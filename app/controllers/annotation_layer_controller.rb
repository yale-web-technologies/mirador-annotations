class AnnotationLayerController < ApplicationController

  # GET /layer
  # GET /layer.json
  def index
    @annotation_layers = AnnotationLayer.all
    respond_to do |format|
      format.html #index.html.erb
      format.json { render json: @annotation_layers }
    end
  end

  # GET /layer/1
  # GET /layer/1.json
  def show
    @annotation_layer = AnnotationLayer.find(params[:id])
    authorize! :show, @annotation_layer
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_layer.to_iiif }
    end
  end

  # GET /layer/new
  # GET /layer/new.json
  def new
    new_id = UUID.generate
    @annotation_layer = AnnotationLayer.new(:@id => base_uri + 'layers/' + new_id)
    @annotation_layer.id = new_id
    authorize! :create, @annotation_layer
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @annotation_layer.to_iiif }
    end
  end

  # GET /layer/1/edit
  def edit
    @annotation_layer = AnnotationLayer.find(params[:id])
  end

  # POST /layer
  # POST /layer.json
  def create
    @annotation_layer = AnnotationLayer.new(params[:annotation_layer])
    @annotation_layer.id = params[:annotation_layer][:id]

    authorize! :create, @annotation_layer
    respond_to do |format|
      if @annotation_layer.save
        format.html { redirect_to @annotation_layer, notice: 'Annotation layer was successfully created.' }
        format.json { render json: @annotation_layer.to_iiif, status: :created, location: @annotation_layer }
      else
        format.html { render action: "new" }
        format.json { render json: @annotation_layer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /layer/1
  # PUT /layer/1.json
  def update
    @annotation_layer = AnnotationLayer.find(params[:id])
    authorize! :update, @annotation_layer
    respond_to do |format|
      if @annotation_layer.update_attributes(params[:annotation_layer])
        format.html { redirect_to @annotation_layer, notice: 'Annotation layer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @annotation_layer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /layer/1
  # DELETE /layer/1.json
  def destroy
    @annotation_layer = AnnotationLayer.find(params[:id])
    authorize! :delete, @annotation_layer
    @annotation_layer.destroy
    respond_to do |format|
      format.html { redirect_to annotation_layers_url }
      format.json { head :no_content }
    end
  end

  protected

  def base_uri
    # Generate annotation ID as URI,  server + "/annotation/" + UUID
    base_uri = Rails.configuration.annotation_server.url
    base_uri += '/' unless base_uri.ends_with?('/')
    base_uri
  end


end
