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
    @list = Hash.new
    @ru = request.original_url
    @ru += '/'   if !@ru.end_with? '/'
    @list['list_id'] = @ru + SecureRandom.uuid
    @within =   JSON.parse(params['list'].to_s)['within']
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
