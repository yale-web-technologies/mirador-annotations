class AnnotationLayerController < ApplicationController
  skip_before_action :verify_authenticity_token

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
    @layerIn = JSON.parse(params.to_json)
    @layer = Hash.new
    @ru = request.original_url
    @ru += '/'   if !@ru.end_with? '/'
    @layer['layer_id'] = @ru + SecureRandom.uuid
    @layer['layer_type'] = @layerIn['@type']
    @layer['label'] = @layerIn['label']
    @layer['motivation'] = @layerIn['motivation']
    #@layer['description'] = @layerIn['description']
    @layer['license'] = @layerIn['license']
    @layer['version'] = 1
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
    @annotationLayerIn = JSON.parse(params.to_json)
    @problem = ''
    if !validate_annotationLayer @annotationLayerIn
      errMsg = "Annotation Layer not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end
    @annotationLayer = AnnotationLayer.where(layer_id: @annotationLayerIn['@id']).first
    #authorize! :update, @annotationLayer

    if @annotationLayer.version.nil? ||  @annotationLayer.version < 1
      @annotationLayer.version = 1
    end

    if !version_layer @annotationLayer
      errMsg = "Annotation Layer could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end

    newVersion = @annotationLayer.version + 1
    respond_to do |format|
      if @annotationLayer.update_attributes(
          :layer_id => @annotationLayerIn['@id'],
          :layer_type => @annotationLayerIn['@type'],
          :label => @annotationLayerIn['label'],
          :motivation => @annotationLayerIn['motivation'],
          :license => @annotationLayerIn['license'],
          :description => @annotationLayerIn['description'],
          :version => newVersion
      )
        format.html { redirect_to @annotationLayer, notice: 'AnnotationLayer was successfully updated.' }
        format.json { render json: @annotationLayer.to_iiif, status: 200 }
      else
        format.html { render action: "edit" }
        format.json { render json: @annotationLayer.errors, status: :unprocessable_entity }
      end
    end
    #end
    #end
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
    if !annotationLayer['@type'].to_s.downcase! == 'sc:layer'
      @problem = "invalid '@type': #{anotationLayer['@type']}"
      valid = false
    end
    if annotationLayer['label'].nil?
      @problem = "missing 'label'"
      valid = false
    end
    valid
  end

  def version_layer layer
    versioned = true
    @allVersion = Hash.new
    @allVersion['all_id'] = layer.layer_id
    @allVersion['all_type'] = layer.layer_type
    @allVersion['all_version'] = layer.version
    #@allVersion['all_version'] = !layer.version.nil? ? layer.version : 1
    @allVersion['all_content'] = layer.to_version_content
    @annotation_layer_version = AnnoListLayerVersion.new(@allVersion)
    #@annotation_layer = AnnotationLayer.new(@layer)
    if !@annotation_layer_version.save
      @problem = "versioning for this record failed"
      versioned = false
    end
    versioned
  end


end
