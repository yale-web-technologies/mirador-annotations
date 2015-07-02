class AnnotationController < ApplicationController


  # GET /list
  # GET /list.json
  def index
    @annotation = Annotation.all
    respond_to do |format|
      format.html #index.html.erb
      #format.json { render json: @annotation }
      iiif = []
      @annotation.each do |annotation|
        iiif << annotation.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif}
    end
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    #@annotation = Annotation.find(params[:id])
    @ru = request.original_url
    p 'ru = ' + @ru.to_s
    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :show, @annotation_list
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation.to_iiif }
    end
  end
end
