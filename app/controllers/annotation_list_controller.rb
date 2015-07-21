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
    @listIn = JSON.parse(params['list'])
    @list = Hash.new
    @ru = request.original_url
    @ru += '/'   if !@ru.end_with? '/'
    @list['list_id'] = @ru + SecureRandom.uuid
    @list['list_type'] = @listIn['@type']
    p  @listIn['label'].to_s
    @list['label'] = @listIn['label']
    @list['description'] = @listIn['description']
    @within =  @listIn['within']
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

  def update
    @annotationListIn = JSON.parse(params['annotationList'].to_json)
    @problem = ''
    if !validate_annotationList @annotationListIn
      errMsg = "AnnotationList record not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      #annotation = Annotation.find(params[:id])
      @annotationList = AnnotationList.where(list_id: @annotationListIn['@id']).first
      #authorize! :update, @annotationList
      respond_to do |format|
        if @annotationList.update_attributes(
            :list_type => @annotationListIn['@type'],
            :label => @annotationListIn['label'],
            :description => @annotationListIn['description']
        )
          format.html { redirect_to @annotationList, notice: 'AnnotationList was successfully updated.' }
          format.json { head :no_content }
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

  def validate_annotationList annotationList
    valid = true
    #if annotationList['@id'].nil?
    #  @problem = "missing @id"
    #  valid = false
    #end
    if !annotationList['@type'].to_s.downcase!.eql? 'sc:annotationlist-o-rama'
      @problem = "invalid '@type'"
      valid = false
    end
    if annotationList['label'].nil?
      @problem = "missing 'label'"
      valid = false
    end
    valid
  end
end
