include AclCreator
require "json"
require "csv"
require 'date'
require "redis"
require 'open-uri'

class AnnotationsController < ApplicationController
  before_action :set_redis , only: [:create, :edit, :update, :destroy, :getAnnotationsForCanvasViaLists]

  include CanCan::ControllerAdditions
  respond_to :json, :text, :csv

  # GET /list
  # GET /list.json
    def index
      @annotation = Annotation.all
      respond_to do |format|
        iiif = []
        @annotation.each do |annotation|
          iiif << annotation.to_iiif
        end
        iiif.to_json
        format.html {render json: iiif}
        format.json {render json: iiif, content_type: "application/json"}
      end
    end

  def get_annotations_for_canvas
    canvas = Canvas.where(id: params['canvas_id']).first
    canvas.annotations
  end

  def getAnnotationsForCanvasViaLists
    annosForCanvas = ''
    @canvas = params['canvas_id']
    if Rails.application.config.useRedis == 'Y'
      annosForCanvas = @redis.get(@canvas)
      if !annosForCanvas.nil?
      else
        annosForCanvas = buildMemAnnosForCanvas @canvas
      end
      annoWLayerArrayUniq = annosForCanvas
    else
      host_url_prefix = Rails.application.config.hostUrl

      bearerToken = ''

      lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{params['canvas_id']}%", "%/lists/%")

      annoWLayerArray = Array.new
      annoWLayerArrayUniq = Array.new

      lists.each do |list|
        layer_id = getLayerFromListName list.list_id
        if !layer_id.nil?
          annotations = ListAnnotationsMap.getAnnotationsForList list.list_id
          annotations.each do |annotation|
            if !annotation.nil? &&
              if !annotation.active==false # [jrl]
                annoWLayerHash= Hash.new
                annoWLayerHash["layer_id"] = layer_id
                annoWLayerHash["annotation"] = annotation.to_iiif
                annoWLayerArray.push(annoWLayerHash)
              end
            end
          end
        end
        annoWLayerArrayUniq = annoWLayerArray.uniq  if !annoWLayerArray.nil?
      end
    end
      respond_to do |format|
        format.html {render json: annoWLayerArrayUniq}
        format.json {render json: annoWLayerArrayUniq, content_type: "application/json"}
      end

  end

  def getLayerFromListName listName
    match = /\/http(\S+\/layers\/\S+_h)/.match(listName)

    if match.nil?
      index1 = listName.index('lists/') + 6
      index2 = listName.index('_')
      layer_id = listName[index1, index2-index1]
      layer_id
    else
      layer_id = match[0]
      layer_id =layer_id[1...-2]
      layer_id = "No layer" if (layer_id.nil?)
      layer_id
    end
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    if Rails.application.config.hostUrl.end_with?("/")
      @ru = Rails.application.config.hostUrl + "annotations/#{params['id']}"
    else
      @ru = Rails.application.config.hostUrl + "/annotations/#{params['id']}"
    end

    @annotation = Annotation.where(annotation_id: @ru).first
    request.format = "json"
    respond_to do |format|
      if !@annotation.nil?
        format.html # show.html.erb
        format.json { render json: @annotation.to_iiif, content_type: "application/json" }
      else
        format.json { render json: nil, status: :ok }
      end
    end
  end

  # POST /annotation
  def create

    @layer_id = params['layer_id']
    @annotationIn = params['annotation']

    @problem = ''

    @ru = Rails.application.config.hostUrl
    @ru += '/' if !@ru.end_with? '/'
    @annotation_id = "#{@ru}annotations/#{SecureRandom.uuid}"

    @annotationOut = Hash.new
    @annotationOut['annotation_id'] = @annotation_id
    @annotationOut['annotation_type'] = @annotationIn['@type']
    @annotationOut['motivation'] = @annotationIn['motivation']
    @annotationOut['description'] = @annotationIn['description']
    @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json

    #TODO: consider if canvas convenience field should be set to original canvas for targeting annotations as well.
    # @annotationOut['canvas']  = @annotationIn['on']['full']

    resource = @annotationIn['resource']
    tags = parse_tags(resource)

    @annotationOut['resource']  = resource.to_json
    @annotationOut['active'] = true
    @annotationOut['version'] = 1
    @annotationOut['on'] = @annotationIn['on'].to_json

    # determine the required list for this layer and canvas (this is project-specific)
    # and create as needed (if this is the first annotation for this layer/canvas)
    # Deal with possibility of 'on' being multiple canvases (or annotations); in this case 'on' will look like an array, which will mean multiple lists
    if !@annotationIn['on'].to_s.start_with?("[")
      # Checks that the list exists
      list_id = handleRequiredList
      @annotationOut['canvas'] = @annotationIn['on']['full']
    else
      handleRequiredListMultipleOn
      @annotationOut['canvas'] = setMultipleCanvas
    end

    @annotation = Annotation.new(@annotationOut)

    unless check_anno_auth(request, @annotation)
      return render_forbidden("There was an error creating the annotation")
    end

    # associate the tags
    tags.each do |tag|
      @annotation.annotation_tags << tag
    end

    # create the annotation/lists association
    create_annotation_acls_via_parent_lists @annotation_id

    request.format = "json"
    respond_to do |format|
      if @annotation.save!
        associate_lists(@annotation, list_id)
        format.json { render json: @annotation.to_iiif, status: :created, content_type: "application/json"} #, location: @annotation }
      else
        format.json { render json: @annotation.errors, status: :unprocessable_entity, content_type: "application/json" }
      end
    end
  end

  # PUT /annotation/1
  # PUT /annotation/1.json
  def update
    @ru = Rails.application.config.hostUrl

    # Determine from the passed-in layer_id if the layer was changed
    editObject = params
    @layerIdIn = editObject['layer_id'][0]
    @annotationIn = editObject['annotation']
    #use @annotationIn['within'] to determine if the anno already belongs to this layer, if so set updateLists = false
    updateLists = true
    @annotationIn['within'].each do |list_id|
      layers_for_list = Annotation.where("annotation_id": @annotationIn["@id"]).first.annotation_layers
      layers_for_list.each do |layer_for_list|
        if layer_for_list["layer_id"] == @layerIdIn
          updateLists = false
          break
        end
      end
    end

    @problem = ''
    @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first

    unless check_anno_auth(request, @annotation)
      return render_forbidden("There was an error updating the annotation")
    end

    #-------
    if @annotation.nil?
      # No annotation found
      format.json { render json: nil, status: :ok }
    else
      if @annotation.version.nil? ||  @annotation.version < 1
        # Correctly assign a version number
        @annotation.version = 1
      end
      if !version_annotation @annotation
        errMsg = "Annotation could not be updated: " + @problem
        render :json => { :error => errMsg },
               :status => :unprocessable_entity
      end

      if updateLists
        list_id =  constructRequiredListId @layerIdIn, @annotation.canvas
        canvas_id = getTargetingAnnosCanvas(@annotation)
        checkListExists(list_id, @layerIdIn, canvas_id)

        @annotationIn['within'] = Array.new
        @annotationIn['within'].push(list_id)

        @annotation.annotation_lists.each do |list|
          delete_annotation_list_association(@annotation.annotation_id, list.list_id)
        end

        # Then reassociate lists and the annotation
        associate_lists_from_within(@annotation, @annotationIn['within'])
      end

      newVersion = @annotation.version + 1
      request.format = "json"
      respond_to do |format|

        if @annotation.update_attributes(
            :annotation_type => @annotationIn['@type'],
            :motivation => @annotationIn['motivation'].to_json,
            :on => @annotationIn['on'].to_json,
            :resource => @annotationIn['resource'].to_json,
            :annotated_by => @annotationIn['annotatedBy'].to_json,
            :version => newVersion,
            :order_weight => @annotationIn['orderWeight']
        )

          # Update tags associated with the annotation
          tags = parse_tags(@annotationIn['resource'])
          @annotation.annotation_tags = tags

          format.html { redirect_to @annotation, notice: 'Annotation was successfully updated.' }
          format.json { render json: @annotation.to_iiif, status: 200, content_type: "application/json"}
        else
          format.html { render action: "edit" }
          format.json { render json: @annotation.errors, status: :unprocessable_entity, content_type: "application/json" }
        end
      end
    end
end

  # DELETE /annotation/1
  # DELETE /annotation/1.json
  def destroy
    request.format = "json"

    @annotation = Annotation.where("annotation_id like ? ", "%#{params['id']}").first

    if @annotation.nil?
      format.json { render json: nil, status: :ok }
    else

      unless check_anno_auth(request, @annotation)
        return render_forbidden("There was an error deleting the annotation")
      end

      if @annotation.version.nil? ||  @annotation.version < 1
        @annotation.version = 1
      end
      if !version_annotation @annotation
        errMsg = "Annotation could not be versioned: " + @problem
        render :json => { :error => errMsg },
               :status => :unprocessable_entity
      end
      @annotation.destroy
      respond_to do |format|
        format.html { redirect_to annotation_layers_url }
        format.json { head :no_content }
      end
    end
  end

  def validate_annotation annotation
    valid = true
    if !annotation['@type'].to_s.downcase! == 'oa:annotation'
      @problem = "invalid '@type' + #{annotation['@type']}"
      valid = false
    end

    if annotation['motivation'].nil?
      @problem = "missing 'motivation'"
      valid = false
    end

    if annotation['on'].nil?
      @problem = "missing 'on' element"
      valid = false
    end

    unless annotation['within'].nil?
      annotation['within'].each do |list_id|
          @annotation_list = AnnotationList.where(list_id: list_id).first
          if @annotation_list.nil?
          end
        end
    end

    if annotation['resource'].nil?
      @problem = "missing 'resource' element"
      valid = false
    end

    puts "ERROR w/ validation: #{@problem}" unless valid
    valid
  end

  def version_annotation annotation
    versioned = true
    @allVersion = Hash.new
    @allVersion['all_id'] = annotation.annotation_id
    @allVersion['all_type'] = annotation.annotation_type
    @allVersion['all_version'] = annotation.version
    @allVersion['all_content'] = annotation.to_version_content
    @annotation_list_version = AnnoListLayerVersion.new(@allVersion)
    if !@annotation_list_version.save
      @problem = "versioning for this record failed"
      versioned = false
    end
    versioned
  end

#########################################################

  def handleRequiredList
    @canvas_id =  @annotationIn['on']['full']
    if (!@annotationIn['on']['full'].to_s.include?('/canvas/'))
      @annotation = Annotation.where(annotation_id:@annotationIn['on']['full']).first
      @canvas_id = getTargetingAnnosCanvas(@annotation)
    end
    @required_list_id = constructRequiredListId @layer_id, @canvas_id
    checkListExists(@required_list_id, @layer_id, @canvas_id)
    @required_list_id
  end

  def handleRequiredListMultipleOn
    #****************************************************
    # multiple "on's" will be an array
    #****************************************************
    @annotationIn['on'].each do |on|
        on = JSON.parse(on.to_json)
        #===================================
        @canvas_id = on['full']
        if (!on['full'].to_s.include?('/canvas/'))
          @annotation = Annotation.where("annotation_id like ? ", "%#{on['full']}%").first
          if !@annotation.nil?
            @canvas_id = getTargetingAnnosCanvas(@annotation)
          end
        end
        @required_list_id = constructRequiredListId @layer_id, @canvas_id if !@canvas_id.nil?
        checkListExists(@required_list_id, @layer_id, @canvas_id)  if !@canvas_id.nil?
        #====================================
    end
  end

  def setMultipleCanvas
    @annotationIn['canvas'] = '|'
    @annotationIn['on'].each do |on|
     @annotationIn['canvas'] +=  on['full'] + '|'
    end
    return @annotationIn['canvas']
  end

  def constructRequiredListId layer_id, canvas_id
    @ru = Rails.application.config.hostUrl
    @ru += '/'   if !@ru.end_with? '/'
    list_id = @ru + "lists/" + layer_id + "_" + canvas_id
  end

  def checkListExists(list_id, layer_id, canvas_id)
    #loosen the match to allow any (previous) list with the passed in layer_id and canvas_id
    @annotation_list = AnnotationList.where(list_id: list_id).first

    if @annotation_list.nil?
      create_annotation_list(list_id, layer_id, canvas_id)
    end
    # add to within if necessary
    if @annotationIn['within'].nil?
      withinArray = Array.new
      withinArray.push(list_id)
      @annotationIn['within'] = withinArray
    else
      if (@annotationIn['within'].kind_of?(Array))
        withinArray = @annotationIn['within']
      else
        withinArray = @annotationIn['within'].to_arr
      end
      withinArray.push(list_id)
      @annotationIn['within'] = withinArray
    end
  end

  def create_annotation_list(list_id, layer_id, canvas_id)
    canvas = Canvas.where(iiif_canvas_id: canvas_id).first
    unless canvas
      canvas = Canvas.create(iiif_canvas_id: canvas_id)
    end
    list = Hash.new
    list['list_id'] = list_id
    list['list_type'] = "sc:annotationlist"
    list['label'] = "Annotation List for: #{canvas_id}"
    list['description'] = ""
    list['version'] = 1
    list['canvas_id'] = canvas.id
    within = Array.new
    within.push(layer_id)
    @annotation_list = AnnotationList.create(list)
    # Layer must already exist -- client selects it from dropdown
    layer = AnnotationLayer.where(layer_id: layer_id).first
    layer.annotation_lists << @annotation_list
    create_list_acls_via_parent_layers(list_id)
  end
##############################################

  def  getTargetingAnnos inputAnnos
    return if (inputAnnos.nil?)
    inputAnnos.each do |anno|
      targetingAnnotations = Annotation.where(canvas:anno.annotation_id)
      getTargetingAnnos targetingAnnotations
      @annotation += targetingAnnotations if !targetingAnnotations.nil?
    end
  end

  #  for lotb
  def getTargetedAnno inputAnno
    return if inputAnno.nil?
    onN = inputAnno.on
    onN.gsub!(/=>/,':')
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end


#  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    return if inputAnno.nil?
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    targetAnnotation = Annotation.where("annotation_id like ? ", "%#{inputAnno.canvas}%").first


    if targetAnnotation.nil?
      return
    else
    getTargetingAnnosCanvas targetAnnotation
    end
  end

  # REST call to return canvas_id for an annotations. A wrapper for getTargetingAnnosCanvas
  def getTargetingAnnosCanvasFromID
    inputID = params['id']
    targetingAnno = Annotation.where(annotation_id: inputID).first
    origCanvasAnno = getTargetingAnnosCanvas(targetingAnno)
    request.format = "json"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: origCanvasAnno, content_type: "application/text" }
    end
  end

  def getLayersForAnnotationREST
    inputID = params['id']
    lists = ListAnnotationsMap.getListsForAnnotation inputID
    layerArray = Array.new
    lists.each do |list_id|
      layerLabels = LayerListsMap.getLayerLabelsForList list_id
      layerHash= Hash.new
      layerLabels.each do |layerLabel|
        layerHash= Hash.new
        layerHash["layer"] = layerLabel
      end
      layerArray.push(layerHash)
    end
    request.format = "json"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: layerArray, content_type: "application/text" }
    end
  end

  def updateSvg
    annotation_id = params['id']
    svg = params['svg']
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    svg = on["selector"]["value"]
    new_svg = "... " + svg
    on["selector"]["value"] = new_svg

    request.format = "json"
  end

  def getSvg
    annotation_id = params['id']
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    svg = on["selector"]["value"]
    render json: on
  end

  def get_svg_path anno
    on = JSON.parse(anno.on)
    svg = on["selector"]["value"]
    svgHash = Hash.from_xml(svg)
    svg_path = svgHash["svg"]["path"]["d"]
  end

  def set_redis
    if !ENV["REDIS_URL"].nil?
      @redis = Redis.new
    else
      @redis = Redis.new(url: ENV["REDIS_URL"])
    end
  end

  def buildMemAnnosForCanvas canvas_id
    host_url_prefix = Rails.application.config.hostUrl
    host_url_prefix = 'localhost:5000/'

    lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{canvas_id}%", "%/lists/%")

    annoWLayerArray = Array.new

    lists.each do |list|
      layer_id = getLayerFromListName list.list_id
      if !layer_id.nil?
        annotations = ListAnnotationsMap.getAnnotationsForList list.list_id
        annotations.each do |annotation|
          if !annotation.nil?
            annoWLayerHash= Hash.new
            annoWLayerHash["layer_id"] = layer_id
            annoWLayerHash["annotation"] = annotation.to_iiif
            annoWLayerArray.push(annoWLayerHash)
          end
        end
      end
    end
    annoWLayerArrayUniq = annoWLayerArray.uniq
    @redis.set(canvas_id, annoWLayerArrayUniq)
  end

  def setRedisKeys
    @redis = Redis.new(url: ENV["REDIS_URL"])

    @canvasKey = params['canvas_id']
    if Rails.application.config.hostUrl.end_with?("/")
      urlForRedisKey = Rails.application.config.hostUrl + "getAnnotationsViaList/?canvas_id=#{@canvasKey}"
    else
      urlForRedisKey  = Rails.application.config.hostUrl + "/getAnnotationsViaList/?canvas_id=#{@canvasKey}"
    end

    redisValue = open(urlForRedisKey).read
    redisValue.gsub!(/=>/,":")
    @redis.set(@canvasKey,redisValue)

    respond_to do |format|
      format.html { render html: 'RedisKey set', status: :ok }
      format.json { render json: '{"RedisKey": "set"}', status: :ok }
    end
  end

  private

  def parse_tags(resource)
    # resource is a JSON object that conforms to IIIF standard
    parsed_tags = []
    # only interested in resources that are a tag
    tags = resource.select { |entry| entry["@type"] == "oa:Tag"}
    return [] if tags.empty?
    tags.each do |entry|
      tag_name = entry["chars"]
      tag = AnnotationTag.where(name: tag_name).first
      # create the tag if not in the db
      if tag.nil?
        tag = AnnotationTag.create(name: tag_name)
      end
      parsed_tags << tag
    end
    parsed_tags
  end

  def check_anno_auth(request, annotation)
    if Rails.application.config.use_jwt_auth
      AnnoAuthValidator.authorize(request.headers['Authorization'], getTargetingAnnosCanvas(annotation))
    else
      true
    end
  end

  def render_forbidden(message)
    render  status: :forbidden, json: { message: message }.to_json
  end

  def get_lists(anno)
    # parses the within field to determine what lists to associate
    within = anno['within']
    return [] if within.nil?
    lists = []
    within.each do |list_id|
      list = AnnotationList.where(list_id: list_id).first
      list = AnnotationList.create(list_id: list_id) if list.nil?
      lists << list unless list.nil?
    end
    lists
  end

  def associate_lists(anno, list_id)
    # lists = get_lists(anno_in)
    list = AnnotationList.where(list_id: list_id).first
    anno.annotation_lists << list unless @annotation.annotation_lists.include?(list)
  end

  def associate_lists_from_within(anno, within)
    within.each do |list_id|
      associate_lists(anno, list_id)
    end
  end

  def delete_annotation_list_association(annotation_id, list_id)
    anno = Annotation.where(annotation_id: annotation_id).first
    list = anno.annotation_lists.where(list_id: list_id).first
    anno.annotation_lists.delete(list) if list
  end
end
