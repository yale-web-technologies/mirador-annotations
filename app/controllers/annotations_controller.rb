include AclCreator
require "json"
require "csv"
require 'date'
require "redis"
require 'open-uri'

class AnnotationsController < ApplicationController
  before_action :set_redis , only: [:create, :edit, :update, :destroy, :doRedis, :getAnnotationsForCanvasViaLists]

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

  def getAnnotationsForCanvasViaLists
    annosForCanvas = ''
    @canvas = params['canvas_id']
    if Rails.application.config.useRedis == 'Y'
      p "redis.get(@canvas: #{@canvas}"
      annosForCanvas = @redis.get(@canvas)
      if !annosForCanvas.nil?
        p "YES: found response in redis for #{params['canvas_id']} :  #{annosForCanvas[1..100]}"
      else
        annosForCanvas = buildMemAnnosForCanvas @canvas
        p "NO: Just added redis record for annos on #{@canvas}"
      end
      annoWLayerArrayUniq = annosForCanvas
    else
      host_url_prefix = Rails.application.config.hostUrl
      p "host url = #{host_url_prefix}"

      bearerToken = ''
      p 'in getAnnotationsForCanvasViaLists: params = ' + params.inspect

      lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{params['canvas_id']}%", "%/lists/%")

      annoWLayerArray = Array.new
      annoWLayerArrayUniq = Array.new
      p "just initted unique array"

      p  "in getAnnotationsForCanvasViaLists: lists.count = #{lists.count}"

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
      p "non-iiif layer_id: #{layer_id}"
      layer_id
    else
      #return if match.nil?
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
    p "AnnotationsController#create params: #{params.inspect}"
    p "hostUrl: #{Rails.application.config.hostUrl}"

    @layer_id = params['layer_id']
    @annotationIn = params['annotation']

    @problem = ''

    @ru = Rails.application.config.hostUrl
    @ru += '/' if !@ru.end_with? '/'
    @annotation_id = "#{@ru}annotations/#{SecureRandom.uuid}"
    p "annotation_id: #{@annotation_id}"

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
    #if @annotationIn['on'].kind_of?(Array)

      handleRequiredList
      @annotationOut['canvas'] = @annotationIn['on']['full']
    else
      handleRequiredListMultipleOn
      @annotationOut['canvas'] = setMultipleCanvas
    end
   
    p "in CreateAnno: @annotationOut['canvas'] = #{@annotationOut['canvas']}"
    p "in CreateAnno: about to setMap: @annotationIn['within'] = #{@annotationIn['within']}"
    ListAnnotationsMap.setMap @annotationIn['within'], @annotation_id
    create_annotation_acls_via_parent_lists @annotation_id
    @annotation = Annotation.new(@annotationOut)
    
    unless check_anno_auth(request, @annotation)
      return render_forbidden("There was an error creating the annotation")
    end

    # associate the tags
    tags.each do |tag|
      @annotation.annotation_tags << tag 
    end
    
    #authorize! :create, @annotation
    request.format = "json"
    p 'about to respond in create'
    respond_to do |format|
      if @annotation.save
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
      p "updateTest: is passed in layer #{@layerIdIn} in [within]"
      layersForList = LayerListsMap.getLayersForList list_id
      layersForList.each do |layerForList|
      p "withinList #{list_id} has layer #{layerForList}"
        if layerForList == @layerIdIn
          updateLists = false
          break
        end
      end
    end
    p "updateLists = #{updateLists}"

    @problem = ''
    @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first

    unless check_anno_auth(request, @annotation)
      return render_forbidden("There was an error updating the annotation")
    end

    #-------
    p 'just searched for this annotation: id = ' + @annotation.annotation_id
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
        p "updating lists for anno: #{@annotation.annotation_id}"
        list_id =  constructRequiredListId @layerIdIn, @annotation.canvas
        canvas_id = getTargetingAnnosCanvas(@annotation)
        p "updating lists: constructed list = #{list_id}"
        checkListExists list_id, @layerIdIn, canvas_id

        @annotationIn['within'] = Array.new
        @annotationIn['within'].push(list_id)

        ListAnnotationsMap.deleteAnnotationFromList @annotation.annotation_id
        p "******* just deleted list_anno_maps for #{ @annotation.annotation_id} *************"
        p "******* within =  #{ @annotationIn['within'].to_s }************"
        ListAnnotationsMap.setMap @annotationIn['within'], @annotation.annotation_id
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
    p 'in annotation_controller:destroy'
    request.format = "json"
    puts "\ndelete params: #{params.to_s}"

    @annotation = Annotation.where("annotation_id like ? ", "%#{params['id']}").first

    if @annotation.nil?
      p 'did not find @annotation for destroy: ' + params['id']
      format.json { render json: nil, status: :ok }
    else

      unless check_anno_auth(request, @annotation)
        return render_forbidden("There was an error deleting the annotation")
      end

      p 'just retrieved @annotation for destroy: ' + @annotation.annotation_id
      #authorize! :delete, @annotation
      if @annotation.version.nil? ||  @annotation.version < 1
        @annotation.version = 1
      end
      if !version_annotation @annotation
        errMsg = "Annotation could not be versioned: " + @problem
        render :json => { :error => errMsg },
               :status => :unprocessable_entity
      end
      ListAnnotationsMap.deleteAnnotationFromList @annotation.annotation_id
      @annotation.destroy
      respond_to do |format|
        p "about to respond in delete"
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
    p 'in HandleRequiredList'
    @canvas_id =  @annotationIn['on']['full']
    p "on-full = #{@annotationIn['on']['full']}"
    if (!@annotationIn['on']['full'].to_s.include?('/canvas/'))
      @annotation = Annotation.where(annotation_id:@annotationIn['on']['full']).first
      @canvas_id = getTargetingAnnosCanvas(@annotation)
    end
    @required_list_id = constructRequiredListId @layer_id, @canvas_id
    checkListExists @required_list_id, @layer_id, @canvas_id
  end

  def handleRequiredListMultipleOn
    #p 'in HandleRequiredListMultipleOn:'
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
        checkListExists @required_list_id, @layer_id, @canvas_id  if !@canvas_id.nil?
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
    puts "AnnotationsController#constructRequiredListId layer_id: #{layer_id}, canvas_id: #{canvas_id}"
    @ru = Rails.application.config.hostUrl
    @ru += '/'   if !@ru.end_with? '/'
    puts "\n"
    p "in constructRequiredListId: layer_id = #{layer_id}  and canvas_id = #{canvas_id}"
    puts "\n"
    list_id = @ru + "lists/" + layer_id + "_" + canvas_id
  end

  def checkListExists list_id, layer_id, canvas_id
    @annotation_list = AnnotationList.where(list_id: list_id).first
    #loosen the match to allow any (previous) list with the passed in layer_id and canvas_id
    @annotation_list = AnnotationList.where(list_id: list_id).first

    if @annotation_list.nil?
      createAnnotationListForMap(list_id, layer_id, canvas_id)
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

  def createAnnotationListForMap list_id, layer_id, canvas_id
    @list = Hash.new
    @list['list_id'] = list_id
    @list['list_type'] = "sc:annotationlist"
    @list['label'] = "Annotation List for: #{canvas_id}"
    @list['description'] = ""
    @list['version'] = 1
    @within = Array.new
    @within.push(layer_id)
    LayerListsMap.setMap @within,@list['list_id']
    create_list_acls_via_parent_layers @list['list_id']
    @annotation_list = AnnotationList.create(@list)
  end

##############################################

  def  getTargetingAnnos inputAnnos
    return if (inputAnnos.nil?)
    inputAnnos.each do |anno|
      p 'getTargetingAnnos: anno_id = ' + anno.annotation_id
      targetingAnnotations = Annotation.where(canvas:anno.annotation_id)
      getTargetingAnnos targetingAnnotations
      @annotation += targetingAnnotations if !targetingAnnotations.nil?
    end
  end

  #  for lotb
  def getTargetedAnno inputAnno
    return if inputAnno.nil?
    onN = inputAnno.on
    p "inputAnno_id = #{inputAnno.annotation_id}"
    p "on string = #{inputAnno.on}"
    onN.gsub!(/=>/,':')
    p "onN = #{onN}"
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end


#  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    return if inputAnno.nil?
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    p "in getTargetingAnnosCanvas: inputAnno.canvas = #{inputAnno.canvas}"
    p "getTargetingAnnosCanvas:                        anno_id = #{inputAnno.annotation_id}  and canvas = #{inputAnno.canvas}"
    targetAnnotation = Annotation.where("annotation_id like ? ", "%#{inputAnno.canvas}%").first


    if targetAnnotation.nil?
      p "in getTargetingAnnosCanvas: got nil annotation from canvas and returning nil"
      return
    else
    p "just got targetAnnotation based on that canvas: anno_id = #{targetAnnotation.annotation_id}  and canvas = #{targetAnnotation.canvas} "
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
    p 'svg passed in: #{svg}'
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    p "on = #{on.to_json}"
    svg = on["selector"]["value"]
    new_svg = "... " + svg
    on["selector"]["value"] = new_svg
    p "new svg = #{new_svg}"

    request.format = "json"
  end

  def getSvg
    annotation_id = params['id']
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    p "on = #{on.to_json}"
    svg = on["selector"]["value"]
    p "svg = #{svg}"
    render json: on
  end

  def get_svg_path anno
    on = JSON.parse(anno.on)
    svg = on["selector"]["value"]
    svgHash = Hash.from_xml(svg)
    svg_path = svgHash["svg"]["path"]["d"]
  end

  # six feeds designed for use by Drupal portal/project mgmg site
  # initial loads for annotations
  # ongoing loads for annotations (updated/created within last 7 days)
  #   both of these will, for convenience:
  #   split for annotations (sans resources) and resources only (plus anno id and a concocted resource id)
  # so:
  # 1a) all annos sans resource
  # 1b) delta annos sans resource last 7
  # 2a) all annos resource only
  # 2b) delta annos resource only last 7
  # 1a & 1b, and 2a & 2b are combined via use of a paramter
  # 3) all layers with same label text as gets sent from the getAnnotationsForCanvas api's
  # 4) all annotation_id's to use as a cross reference for consumer to synchronize deletions

  def feedAllAnnoIds
    @annotation = Annotation.all
    allAnnoIds = CSV.generate do |csv|
      headers = "annotation_id"
      csv << [headers]
      @annotation.each do |annotation|
        csv << [annotation.annotation_id]
      end
    end
    respond_with do |format|
      format.json {render :text => allAnnoIds}
      format.text {render :text => allAnnoIds}
    end
  end

  def feedAllLayers
    @layer = AnnotationLayer.all
    allLayers = CSV.generate do |csv|
      headers = "layer_label"
      csv << [headers]
      @layer.each do |layer|
        csv << [layer.label]
      end
    end
    response.content_type ='xml'

    respond_with do |format|
      format.text {render :text => allLayers, :content_type => Mime::TEXT.to_s}
    end
  end

  # simple Redis test
  def doRedis
    @redis.set("royKey", '{"royKey":"Roys Key"}')
    royKey = @redis.get("royKey")
    royKey = JSON.parse(@redis.get("royKey"))
    p "royKey = #{royKey}"
    respond_with do |format|
      format.text {render :text => royKey, content_type: "application/json"}
      format.json {render :text => royKey, content_type: "application/json"}
    end
  end

  def set_redis
    p 'in set_redis'
    if !ENV["REDIS_URL"].nil?
      @redis = Redis.new
    else
      @redis = Redis.new(url: ENV["REDIS_URL"])
    end
  end

  def buildMemAnnosForCanvas canvas_id
    host_url_prefix = Rails.application.config.hostUrl
    host_url_prefix = 'localhost:5000/'
    p "host url = #{host_url_prefix}"
    p "buildMemAnnosForCanvas: canvas = #{canvas_id}"

    ###!!!! change back so second query is active
    #lists = AnnotationList.where("list_id like ? and list_id like ?", "%#{canvas_id}%", "%/lists/%")
    lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{canvas_id}%", "%/lists/%")

    annoWLayerArray = Array.new

    p  "in buildMemAnnosForCanvas: lists for this canvas: #{lists.count}"
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

    p "setRedisKeys: env[redis_url'] = #{ENV['REDIS_URL']}"
    p "setRedisKeys: about to set redisKey for #{@canvasKey}"
    p "setRedisKeys: urlForRedisKey = #{urlForRedisKey}"

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

end
