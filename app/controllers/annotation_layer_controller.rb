class AnnotationLayerController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :html, :json

  # GET /layer
  # GET /layer.json
  def index
    @annotation_layers = AnnotationLayer.all
    respond_to do |format|
      format.html #index.html.erb
      #format.json { render json: @annotation_layers }

      iiif = []
      @annotation_layers.each do |annotation_layer|
        iiif << annotation_layer.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif}
    end
  end

  # GET /layer/1
  # GET /layer/1.json
  def show
    p 'params[:id] = ' + params[:id]
    #@annotation_layer = AnnotationLayer.find(params[:id])

    @ru = request.original_url
    @annotation_layer = AnnotationLayer.where(layer_id: @ru).first

    #authorize! :show, @annotation_layer
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_layer.to_iiif }
    end
  end

  # GET /layer/newby
  # GET /layer/newby.json
  def new
    #new_id = UUID.generate
   # @annotation_layer = AnnotationLayer.newby(:layerid => base_uri + 'layers/' + new_id)
    #@annotation_layer.id = new_id
    #authorize! :create, @annotation_layer
    #respond_to do |format|
      #p 'format = ' + format.to_s
      #format.html
      #format.json { render json: @annotation_layer.to_iiif }
    #end
  end

  # GET /layer/1/edit
  def edit
    @annotation_layer = AnnotationLayer.find(params[:id])
  end

  # POST /layer
  # POST /layer.json
  def create
    @layerIn = JSON.parse(params['layer'])
    @layer = Hash.new
    #@layer['layer_id'] = @layerIn['@id']
    @ru = request.original_url
    @ru += '/'   if !@ru.end_with? '/'
    @layer['layer_id'] = @ru + SecureRandom.uuid

    p 'layer_id = ' + @layer['layer_id']


    @layer['layer_type'] = @layerIn['@type']
    @layer['label'] = @layerIn['label']
    @layer['motivation'] = @layerIn['motivation']
    #@layer['description'] = @layerIn['description']
    @layer['license'] = @layerIn['license']
    #@layer['othercontent'] = @layerIn['otherContent']
    @annotation_layer = AnnotationLayer.new(@layer)

    #authorize! :create, @annotation_layer
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
