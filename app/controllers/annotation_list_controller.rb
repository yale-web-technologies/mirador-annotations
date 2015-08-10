class AnnotationListController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :html, :json

  # GET /list
  # GET /list.json
  def index
    @annotation_lists = AnnotationList.all
    respond_to do |format|
      format.html #index.html.erb
      iiif = []
      @annotation_lists.each do |annotation_list|
        iiif << annotation_list.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif}
    end
  end

  # GET /list/1
  # GET /list/1.json
  def show
    @ru = request.original_url
    @annotation_list = AnnotationList.where(list_id: @ru).first
    #authorize! :show, @annotation_list
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_list.to_iiif }
    end
  end

  # POST /list
  # POST /list.json
  def create
    @annotationListIn = JSON.parse(params.to_json)
    p @annotationListIn.to_json
    @problem = ''
    if !validate_annotationList @annotationListIn
      errMsg = "AnnotationList record not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @list = Hash.new
      @ru = request.original_url
      @ru += '/'   if !@ru.end_with? '/'
      @list['list_id'] = @ru + SecureRandom.uuid
      @list['list_type'] = @annotationListIn['@type']
      @list['label'] = @annotationListIn['label']
      @list['description'] = @annotationListIn['description']
      @list['version'] = 1
      @within =  @annotationListIn['within']
      LayerListsMap.setMap @within,@list['list_id']
      @annotation_list = AnnotationList.new(@list)
      #authorize! :create, @annotation_list
      respond_to do |format|
        if @annotation_list.save
          format.html { redirect_to @annotation_list, notice: 'Annotation list was successfully created.' }
          format.json { render json: @annotation_list.to_iiif, status: :created, location: @annotation_list }
        else
          format.html { render action: "new" }
          format.json { render json: @annotation_list.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    @annotationListIn = JSON.parse(params.to_json)
    @problem = ''
    if !validate_annotationList @annotationListIn
      errMsg = "Annotation List not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end

    @annotationList = AnnotationList.where(list_id: @annotationListIn['@id']).first
    #authorize! :update, @annotationList

    if @annotationList.version.nil?
      @annotationList.version = 1
    else
      if @annotationList.version < 1
        @annotationList.version = 1
      end
    end

    if !version_list @annotationList
      errMsg = "Annotation List could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end

    # rewrite the ListAnnotationsMap for this annotation: first delete, then re-write based on ['within']
    LayerListsMap.deleteListFromLayer @annotationList.list_id
    LayerListsMap.setMap @annotationListIn['within'],@annotationList.list_id
    newVersion = @annotationList.version + 1
    respond_to do |format|
      if @annotationList.update_attributes(
          :list_type => @annotationListIn['@type'],
          :label => @annotationListIn['label'],
          :version => newVersion
      )
        format.html { redirect_to @annotationList, notice: 'AnnotationList was successfully updated.' }
        format.json { render json: @annotationList.to_iiif, status: 200}
        #format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @annotationList.errors, status: :unprocessable_entity }
      end
    end
    #end
  end

  # DELETE /list/1
  # DELETE /list/1.json
  def destroy
    @ru = request.original_url
    @annotationList = AnnotationList.where(list_id: @ru).first
    #authorize! :delete, @annotation_list
    LayerListsMap.deleteListFromLayer @annotationList.list_id
    @annotationList.destroy
    respond_to do |format|
      format.html { redirect_to annotation_layers_url }
      format.json { head :no_content }
    end
  end

  protected

  def validate_annotationList annotationList
    valid = true
    if !annotationList['@type'].to_s.downcase! == 'sc:annotationlist'
      @problem = "invalid @type: " + annotationList['@type']
      valid = false
    end
    unless annotationList['within'].nil?
      annotationList['within'].each do |layer_id|
        @annotation_layer = AnnotationLayer.where(layer_id: layer_id).first
        if @annotation_layer.nil?
          @problem = "'within' element: Annotation Layer " + layer_id + " does not exist"
          valid = false
        end
      end
    end
    if annotationList['label'].nil?
      @problem = "missing 'label'"
      valid = false
    end
    valid
  end

  def version_list list
    versioned = true
    @allVersion = Hash.new
    @allVersion['all_id'] = list.list_id
    @allVersion['all_type'] = list.list_type
    @allVersion['all_version'] = list.version
    @allVersion['all_content'] = list.to_version_content
    @annotation_list_version = AnnoListLayerVersion.new(@allVersion)
    if !@annotation_list_version.save
      @problem = "versioning for this record failed"
      versioned = false
    end
    versioned
  end

end
