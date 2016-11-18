class AnnotationLayersController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :html, :json

  # GET /layer
  # GET /layer.json
  def index
    # filter query by param['group_id'] if it exists
    if params['group_id']
      group = Group.where(group_id: params['group_id']).first
      @annotation_layers = Array.new
      @annotation_layers = group.annotation_layers if !group.nil?
    else
      @annotation_layers = AnnotationLayer.all#.order("layer_id")
    end
    p "index: params.inspect " +      params.inspect
    p "index: params[id] = #{params['id']}"
    respond_to do |format|
      format.html #index.html.erb
      iiif = []
      @annotation_layers.each do |annotation_layer|
        iiif << annotation_layer.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif, content_type: "application/json"}
    end
  end

  # GET /layer/1
  # GET /layer/1.json
  def show
    p "show: params.inspect " +  params.inspect
    p "show: params[id] = #{params['id']}"
    #@ru = request.original_url
    @ru = request.protocol + request.host_with_port + "/layers/#{params['id']}"
    #@ru = params['id']
    p "@ru for get = #{@ru}"
    @annotation_layer = AnnotationLayer.where(layer_id: @ru).first
    #authorize! :show, @annotation_layer
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation_layer.to_iiif, content_type: "application/json" }
    end
  end

  # POST /layer
  # POST /layer.json
  def create
    @layerIn = JSON.parse(params.to_json)
    @layer = Hash.new
    #@ru = request.original_url
    @ru = request.original_url.split('?').first
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
    request.format = "json"
    respond_to do |format|
      if @annotation_layer.save
        format.html { redirect_to @annotation_layer, notice: 'Annotation layer was successfully created.' }
        format.json { render json: @annotation_layer.to_iiif, status: :created, location: @annotation_layer, content_type: "application/json" }
      else
        format.html { render action: "new" }
        format.json { render json: @annotation_layer.errors, status: :unprocessable_entity, content_type: "application/json" }
      end
    end
  end

  # not currently used
  def createWithGroup
    @layerIn = JSON.parse(params['layer'].to_json)
    @group_id = params['group_id']
    @permissions = params['permissions'] || ''

    @layer = Hash.new
    #@ru = request.original_url
    #@ru = request.original_url.split('?').first
    #@ru += '/'   if !@ru.end_with? '/'
    #@layer['layer_id'] = @ru + SecureRandom.uuid
    @layer['layer_id'] = @layerIn['layer_id']
    @layer['layer_type'] = @layerIn['@type']
    @layer['label'] = @layerIn['label']
    @layer['motivation'] = @layerIn['motivation']
    #@layer['description'] = @layerIn['description']
    @layer['license'] = @layerIn['license']
    @layer['version'] = 1
    @annotation_layer = AnnotationLayer.new(@layer)

    #authorize! :create, @annotation_layer
    request.format = "json"


    # now check group exists; create if needed
    groups = Group.where(:group_id => params['group_id'])
    p "checked for group: result count = #{groups.count}"
    if groups.count == 0
      p "creating group for #{params['group_id']}"
      group = Group.create(
          group_id: params['group_id'],
          group_description: "test",
          roles: "",
          permissions: @permissions
      )
      p "group #{params['group_id']} created"
      else group = groups.first
    end

    # now push user to groups via has-and-belongs-to-many relationship which uses the groups_users table
    @annotation_layer.groups << group
    p "group #{group.group_id} pushed to layer.groups"
    group.annotation_layers << @annotation_layer
    p "annotation #{@annotation_layer.layer_id} pushed to group.layers"

    respond_to do |format|
      if @annotation_layer.save
        format.html { redirect_to @annotation_layer, notice: 'Annotation layer was successfully created.' }
        format.json { render json: @annotation_layer.to_iiif, status: :created, location: @annotation_layer, content_type: "application/json" }
      else
        format.html { render action: "new" }
        format.json { render json: @annotation_layer.errors, status: :unprocessable_entity, content_type: "application/json" }
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
    else

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
      request.format = "json"
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
          format.json { render json: @annotationLayer.to_iiif, status: 200, content_type: "application/json" }
        else
          format.html { render action: "edit" }
          format.json { render json: @annotationLayer.errors, status: :unprocessable_entity, content_type: "application/json" }
        end
      end
    end
  end

  # DELETE /layer/1
  # DELETE /layer/1.json
  def destroy
    #@ru = request.original_url
    @ru = request.protocol + request.host_with_port + "/layers/#{params['id']}"
    @annotationLayer = AnnotationLayer.where(layer_id: @ru).first
    #authorize! :delete, @annotation_layer
    if @annotationLayer.version.nil? ||  @annotationLayer.version < 1
      @annotationLayer.version = 1
    end
    if !version_layer @annotationLayer
      errMsg = "Annotation Layer could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end
    @annotationLayer.destroy
    request.format = "json"
    respond_to do |format|
      format.html { redirect_to annotation_layers_url }
      format.json { head :no_content }
    end
  end

  # not currently used
  def remove_layer_from_group
    layer = AnnotationLayer.where(layer_id: params[:layer_id]).first

    p "found layer has layer_id: #{layer.layer_id} and id: #{layer.id.to_s} and parameter group_id = #{params['group_id']}"
    group = layer.groups.where(group_id: params[:group_id]).first

    if group
      p "found matching group #{group.group_id}"
      layer.groups.delete(group)
    end
    respond_to do |format|
      format.html { head :no_content  }
      format.json { head :no_content }
    end
  end



  def setCurrentLayers
    layersIn = JSON.parse(params['layers'].to_json)
    group_id = params['group_id']
    group_description = params['group_description']
    #@permissions = params['permissions'] || ''

    # check that group exists; if not create it so we can push these layers to it
    groups = Group.where(:group_id => group_id)
    p "checked for group: result count = #{groups.count}"
    if groups.count == 0
      p "creating group for #{group_id}"
      group = Group.create(
          group_id: group_id,
          group_description: group_description,
          roles: "",
      #permissions: @permissions
      )
      p "group #{group_id} created"
    else
      group = groups.first
    end

    # get the layers for this group
    @layerIds = Array.new
    layersIn.each do |layerIn|
      p "layerIn = #{layerIn}"

      @layerIds.push(layerIn['layer_id'])
      layers =  AnnotationLayer.where(:layer_id => layerIn['layer_id'])
      p "checked for layer #{layerIn['layer_id']}: result count = #{layers.count}"
      if layers.count == 0
        p "creating layer for #{layerIn['layer_id']}"
        @layer = Hash.new
        @layer['layer_id'] = layerIn['layer_id']
        @layer['label'] = layerIn['label']
        @layer['layer_type'] = layerIn['@type'] || "sc:layer"
        @layer['motivation'] = layerIn['motivation'] || "oa:commenting"
        @layer['license'] = layerIn['license'] || "http://creativecommons.org/licenses/by/4.0/"
        @layer['description'] = layerIn['description']
        @layer['version'] = 1
        @annotation_layer = AnnotationLayer.new(@layer)
        @annotation_layer.save
        p "layer #{layerIn['layer_id']} created"
      else @annotation_layer = layers.first
      end

      # push layer to groups via has-and-belongs-to-many relationship which uses the annotation_layers_groups table
      @annotation_layer.groups << group
      p "group #{group.group_id} pushed to layer.groups"
      #group.annotation_layers << @annotation_layer
      #p "annotation #{@annotation_layer.layer_id} pushed to group.layers"
    end

    # check all current group-layers ; delete any that are not in the current params.
    layersForGroup = group.annotation_layers
    layersForGroup.each do |layerForGroup|
      if !@layerIds.include? layerForGroup.layer_id
        group.annotation_layers.delete(layerForGroup.layer_id)
      end
    end

    respond_to do |format|
      #authorize! :create, @annotation_layer
      if @annotation_layer.save
        format.html { redirect_to @annotation_layer, notice: 'Annotation layer was successfully created.' }
        format.json { render json: @annotation_layer.to_iiif, status: :created, location: @annotation_layer, content_type: "application/json" }
      else
        format.html { render action: "new" }
        format.json { render json: @annotation_layer.errors, status: :unprocessable_entity, content_type: "application/json" }
      end
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
    @allVersion['all_content'] = layer.to_version_content
    @annotation_layer_version = AnnoListLayerVersion.new(@allVersion)
    if !@annotation_layer_version.save
      @problem = "versioning for this record failed"
      versioned = false
    end
    versioned
  end

  # receive a group id and array of layers.
  # create the group if it does not exist
  # iterate through array of layers:
  #   - if layer does not exist, create it
  #   - if the layer-group mapping does not exist, create it
  # delete any layer group mappings on the server which were not in the layer array params


end
