include AclCreator

class AnnotationListsController < ApplicationController

  skip_before_action :verify_authenticity_token

  respond_to :json #; :html, :json

  # GET /list
  # GET /list.json
  def index
    @annotation_lists = AnnotationList.all
    respond_to do |format|
      #format.html #index.html.erb
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
    #@ru = request.protocol + request.host_with_port + "/lists/#{params['id']}"
    p "in lists#show: @ru = #{@ru}"
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
    @problem = ''
    if !validate_annotationList @annotationListIn
      errMsg = "AnnotationList record not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @list = Hash.new
      #@ru = request.original_url
      @ru = request.original_url.split('?').first
      @ru += '/'   if !@ru.end_with? '/'
      @list['list_id'] = @ru + SecureRandom.uuid
      @list['list_type'] = @annotationListIn['@type']
      @list['label'] = @annotationListIn['label']
      @list['description'] = @annotationListIn['description']
      @list['version'] = 1
      @within =  @annotationListIn['within']
      LayerListsMap.setMap @within,@list['list_id']
      create_list_acls_via_parent_layers @list['list_id']
      @annotation_list = AnnotationList.new(@list)
      #authorize! :create, @annotation_list
      request.format = "json"
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
    else
      @annotationList = AnnotationList.where(list_id: @annotationListIn['@id']).first
      #authorize! :update, @annotationList

      if @annotationList.version.nil? ||  @annotationList.version < 1
        @annotationList.version = 1
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
      request.format = "json"
      respond_to do |format|
        if @annotationList.update_attributes(
            :list_type => @annotationListIn['@type'],
            :label => @annotationListIn['label'],
            :version => newVersion
        )
          format.html { redirect_to @annotationList, notice: 'AnnotationList was successfully updated.' }
          format.json { render json: @annotationList.to_iiif, status: 200}
        else
          format.html { render action: "edit" }
          format.json { render json: @annotationList.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /list/1
  # DELETE /list/1.json
  def destroy
    #@ru = request.original_url
    @ru = request.protocol + request.host_with_port + "/lists/#{params['id']}"
    @annotationList = AnnotationList.where(list_id: @ru).first
    #authorize! :delete, @annotation_list

    if @annotationList.version.nil? ||  @annotationList.version < 1
      @annotation.version = 1
    end
    if !version_list @annotationList
      errMsg = "AnnotationList could not be versioned: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end
    LayerListsMap.deleteListFromLayer @annotationList.list_id
    @annotationList.destroy
    respond_to do |format|
      format.html { redirect_to annotation_layers_url }
      format.json { head :no_content }
    end
  end

  def CORS_preflight
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def resequence_list
    layer_id = params['layer_id']
    canvas_id = params['canvas_id']
    p "annotations_id = #{params['annotation_ids']}"
    annotation_ids = Array.new
    annotation_ids = params['annotation_ids'].split(",")
    #anno_id.gsub!(/\[/,'')
    #anno_id.gsub!(/\]/,'')
    p "processed annotations_id = #{annotation_ids}"
    ru = request.original_url.split('/resequence').first
    ru += '/'   if !ru.end_with? '/'
    list_id = ru + "lists/" + layer_id + "_" + canvas_id
    puts "resequence_list: constructed list_id: #{list_id}"
    within = Array.new
    within.push(list_id)
    # Clear the maps of all entries for this list
    ListAnnotationsMap.deleteAnnotationsFromList list_id
    # Now rewrite the maps for this list based on annotation_ids array passed in
    annotation_ids.each do |anno_id|
      anno_id = anno_id.to_s
      anno_id.gsub!(/"/,'')
      p "in resequence_id: anno_id = #{anno_id}"
      ListAnnotationsMap.setMap within, anno_id
    end
    request.format = "json"
    respond_to do |format|
      response_msg = '{"list_id":"' + list_id + '"}'
      format.json { render json:response_msg} #, status: :resequenced}
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
