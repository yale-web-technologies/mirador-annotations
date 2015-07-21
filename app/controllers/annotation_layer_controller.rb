class AnnotationLayerController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :html, :json

  # GET /layer
  # GET /layer.json
  def index
    @annotation_layers = AnnotationLayer.all
    respond_to do |format|
      format.html #index.html.erb
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
    @ru = request.original_url
    @annotation_layer = AnnotationLayer.where(layer_id: @ru).first
    #authorize! :show, @annotation_layer
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_layer.to_iiif }
    end
  end

  # POST /layer
  # POST /layer.json
  def create
    @layerIn = JSON.parse(params['layer'])
    @layer = Hash.new
    @ru = request.original_url
    @ru += '/'   if !@ru.end_with? '/'
    @layer['layer_id'] = @ru + SecureRandom.uuid
    @layer['layer_type'] = @layerIn['@type']
    @layer['label'] = @layerIn['label']
    @layer['motivation'] = @layerIn['motivation']
    #@layer['description'] = @layerIn['description']
    @layer['license'] = @layerIn['license']
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
    @annotationLayerIn = JSON.parse(params['annotationLayer'].to_json)
    @problem = ''
    if !validate_annotationLayer @annotationLayerIn
      errMsg = "AnnotationLayer record not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @annotationLayer = AnnotationLayer.where(layer_id: @annotationLayerIn['@id']).first
      #authorize! :update, @annotation
      respond_to do |format|
        if @annotationLayer.update_attributes(
            :layer_id => @annotationLayerIn['@id'],
            :layer_type => @annotationLayerIn['@type'],
            :label => @annotationLayerIn['label'],
            :motivation => @annotationLayerIn['motivation'],
            :license => @annotationLayerIn['license'],
            :description => @annotationLayerIn['description']
        )
          format.html { redirect_to @annotationLayer, notice: 'AnnotationLayer was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @annotationLayer.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /layer/1
  # DELETE /layer/1.json
  def destroy
    @ru = request.original_url
    @annotation_layer = AnnotationLayer.where(layer_id: @ru).first
    #authorize! :delete, @annotation_layer
    @annotation_layer.destroy
    respond_to do |format|
      format.html { redirect_to annotation_layers_url }
      format.json { head :no_content }
    end
  end

  protected

  def validate_annotationLayer annotationLayer
    valid = true
    if !annotationLayer['@type'].to_s.downcase!.eql? 'sc:layer'
      @problem = "invalid '@type'"
      valid = false
    end
    if annotationLayer['label'].nil?
      @problem = "missing 'label'"
      valid = false
    end
    valid
  end


end
