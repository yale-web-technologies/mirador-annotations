class AnnotationListController < ApplicationController


  # GET /list
  # GET /list.json
  def index
    @annotation_lists = AnnotationList.all
    respond_to do |format|
      format.html #index.html.erb
      #format.json { render json: @annotation_lists }
      iiif = []
      @annotation_lists.each do |annotation_list|
        iiif << annotation_list.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif}
    end
  end

  # GET /layer/1
  # GET /layer/1.json
  def show
    @annotation_list = AnnotationList.find(params[:id])
    @ru = request.original_url
    @annotation_layer = AnnotationLayer.where(layer_id: @ru).first
    #authorize! :show, @annotation_list
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_list.to_iiif }
    end
  end
end
