include AclCreator
require "json"
require "csv"
require 'date'
require "redis"
require 'open-uri'

class AnnotationsController < ApplicationController
  before_action :set_redis , only: [:create, :edit, :update, :destroy, :doRedis, :getAnnotationsForCanvasViaLists]

  include CanCan::ControllerAdditions
  #skip_before_action :verify_authenticity_token
  #before_action :authenticate_user!
  respond_to :json, :text, :csv

  # GET /list
  # GET /list.json
    def index
      @annotation = Annotation.all
      respond_to do |format|
        #format.html #index.html.erb
        #format.json { render json: @annotation }
        iiif = []
        @annotation.each do |annotation|
          iiif << annotation.to_iiif
          #p annotation.to_iiif
        end
        iiif.to_json
        format.html {render json: iiif}
        format.json {render json: iiif, content_type: "application/json"}
      end
    end


  def getAnnotationsForCanvasViaListsPreRedis
    # add redis
    annosForCanvas = ''
    @canvas = params['canvas_id']
    p "redis.get(@canvas: #{@canvas}"
    annosForCanvas = @redis.get(@canvas)
    if !annosForCanvas.nil?
      annoWLayerArrayUniq = annosForCanvas
      p "YES: found response in redis for #{params['canvas_id']} :  #{annosForCanvas[1..100]}"
      #@redis.del(@canvas)
    ##
    else
        # replace @ru with hostUrl environment variable
        host_url_prefix = Rails.application.config.hostUrl
        #host_url_prefix = 'localhost:5000/'
        p "host url = #{host_url_prefix}"

        bearerToken = ''
        p 'in getAnnotationsForCanvasViaLists: params = ' + params.inspect
        #p 'in getAnnotationsForCanvasViaLists: headers: ' + request.headers.inspect
        bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
        #p "bearerToken = #{bearerToken}"
        if (bearerToken)
          @user = signInUserByBearerToken bearerToken
        end

        ###!!!! change back so second query is active
        lists = AnnotationList.where("list_id like ? and list_id like ?", "%#{params['canvas_id']}%", "%/lists/%")
        #lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{params['canvas_id']}%", "%/lists/%")

        annoWLayerArray = Array.new

        p  "in getAnnotationsForCanvasViaLists: lists.count = #{lists.count}"
        lists.each do |list|
          layer_id = getLayerFromListName list.list_id
          if !layer_id.nil?
            annotations = ListAnnotationsMap.getAnnotationsForList list.list_id
            annotations.each do |annotation|
              #if !annotation.nil?
              if !annotation.nil? && @canvas = annotation
                annoWLayerHash= Hash.new
                annoWLayerHash["layer_id"] = layer_id
                annoWLayerHash["annotation"] = annotation.to_iiif
                annoWLayerArray.push(annoWLayerHash)
              end
            end
          end
        end
        annoWLayerArrayUniq = annoWLayerArray.uniq
        @redis.set(@canvas, annoWLayerArrayUniq)
     end
    respond_to do |format|
      format.html {render json: annoWLayerArrayUniq}
      format.json {render json: annoWLayerArrayUniq, content_type: "application/json"}
    end
  end

  def getAnnotationsForCanvasViaLists
    annosForCanvas = ''
    @canvas = params['canvas_id']
    if Rails.application.config.useRedis == 'Y'
      p "redis.get(@canvas: #{@canvas}"
      #annoWLayerArrayUniq = @redis.get(@canvas)
      annosForCanvas = @redis.get(@canvas)
      if !annosForCanvas.nil?
        #annoWLayerArrayUniq = annosForCanvas
        p "YES: found response in redis for #{params['canvas_id']} :  #{annosForCanvas[1..100]}"
      else
        #annoWLayerArrayUniq = buildMemAnnosForCanvas @canvas
        annosForCanvas = buildMemAnnosForCanvas @canvas
        #annosForCanvas = @redis.get(@canvas)
        p "NO: Just added redis record for annos on #{@canvas}"
      end
      annoWLayerArrayUniq = annosForCanvas
    else
      host_url_prefix = Rails.application.config.hostUrl
      p "host url = #{host_url_prefix}"

      bearerToken = ''
      p 'in getAnnotationsForCanvasViaLists: params = ' + params.inspect
      #p 'in getAnnotationsForCanvasViaLists: headers: ' + request.headers.inspect
      #bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
      #p "bearerToken = #{bearerToken}"
      #if (bearerToken)
      #  @user = signInUserByBearerToken bearerToken
      #end

      ###!!!! change back so second query is active
      #lists = AnnotationList.where("list_id like ? and list_id like ?", "%#{params['canvas_id']}%", "%/lists/%")
      lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#{params['canvas_id']}%", "%/lists/%")

      annoWLayerArray = Array.new

      p  "in getAnnotationsForCanvasViaLists: lists.count = #{lists.count}"
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
      #annoWLayerArray.gsub!(/=>/,':')
      annoWLayerArrayUniq = annoWLayerArray.uniq

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
    #authorize! :show, @annotation_list
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
    #@annotationIn = params
    # for new params with layer_id and annotation
    @paramsIn = params
    @layer_id = @paramsIn['layer_id']
    #!!! uncomment below and lose the hardcode test
    @annotationIn = @paramsIn['annotation']
    p  "in CreateAnno @annotationIn = #{@annotationIn.to_s}"
    #@annotationIn = JSON.parse(@annotationIn)

=begin
    # Hardcode this test
    @layer_id = "http://mirador-annotation-tenkr-stg.herokuapp.com/layers/18e7f773-e1af-4fb6-a303-4f2a4c5d90e9"
    @annotationIn = '{
    "@type": "oa:Annotation",
    "@context": "http://iiif.io/api/presentation/2/context.json",
    "motivation": [
      "oa:commenting"
    ],
    "resource": [
      {
        "@type": "dctypes:Text",
        "format": "text/html",
        "chars": "<p>test array</p>"
      }
    ],
    "on": [
      {
        "@type": "oa:SpecificResource",
        "full": "http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116",
        "selector": {
          "@type": "oa:Choice",
          "default": {
            "@type": "oa:FragmentSelector",
            "value": "xywh=204,357,168,191"
          },
          "item": {
            "@type": "oa:SvgSelector"
}
},
        "within": {
          "@id": "http://manifest.tenthousandrooms.yale.edu/node/311/manifest",
          "@type": "sc:Manifest"
        }
      }
    ]
  }'
    # End of Hardcode test
=end
    @annotationIn = JSON.parse(@annotationIn.to_s)
    puts "\n"
    p '============================================================================='
    p  "in CreateAnno params = #{params.inspect}"
    p  "in CreateAnno @layer_id = #{params['layer_id']}"
    p  "in CreateAnno @layer_id = #{@layer_id}"
    p  "in CreateAnno @annotationIn['@type'] = #{@annotationIn['@type']}"

    p  "in CreateAnno @annotationIn['resource'] = #{@annotationIn['resource'].to_s}"
    p '============================================================================='
    puts "\n"

    @problem = ''
    #if !validate_annotation @annotationIn
    #  errMsg = "Annotation record not valid and could not be saved: " + @problem
    #  render :json => { :error => errMsg },
    #         :status => :unprocessable_entity
    #else
      #@ru = request.original_url.split('?').first
      # replace @ru with hostUrl environment variable
      p "host url = #{Rails.application.config.hostUrl}"
      @ru = Rails.application.config.hostUrl + "annotations"
      @ru += '/'   if !@ru.end_with? '/'

      @annotation_id = @ru + SecureRandom.uuid
      p "annotation_id = #{@annotation_id}"

      @annotation_id = @annotation_id + SecureRandom.uuid

      @annotationOut = Hash.new
      @annotationOut['annotation_id'] = @annotation_id
      @annotationOut['annotation_type'] = @annotationIn['@type']
      @annotationOut['motivation'] = @annotationIn['motivation']
      @annotationOut['description'] = @annotationIn['description']
      @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json
      #TODO: consider if canvas convenience field should be set to original canvas for targeting annotations as well.
      #@annotationOut['canvas']  = @annotationIn['on']['full']
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['active'] = true
      @annotationOut['version'] = 1

#=====================================================================
      # hardcode a multiple on as test for multiple on's:
      #@annotationIn['on'] =
#'[{"@type": "oa:Annotation","full": "http://mirador-annotations-tenkr-stg.herokuapp.com/annotations/6172538a-3433-4eb5-aaa6-de6c562ab7ab"},{"@type": "oa:Annotation","full": "http://manifest.tenthousandrooms.yale.edu/node/311/canvas/14116"}]'
#=====================================================================
      @annotationOut['on'] = @annotationIn['on']
      p "@annotationIn['on'] = #{@annotationIn['on']}"

      # determine the required list for this layer and canvas (this is project-specific)
      # and create as needed (if this is the first annotation for this layer/canvas)
      # Deal with possibility of 'on' being multiple canvases (or annotations); in this case 'on' will look like an array, which will mean multiple lists
      if !@annotationIn['on'].to_s.start_with?("[")
      #if @annotationIn['on'].kind_of?(Array)
        handleRequiredList
      else
        handleRequiredListMultipleOn
      end

      ListAnnotationsMap.setMap @annotationIn['within'], @annotation_id
      create_annotation_acls_via_parent_lists @annotation_id
      @annotation = Annotation.new(@annotationOut)
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
    #end
  end

  # PUT /annotation/1
  # PUT /annotation/1.json
  def update
    p "in update"
    #@ru = request.original_url
    @ru = Rails.application.config.hostUrl

    # Determine from the passed-in layer_id if the layer was changed
    editObject = JSON.parse(params.to_json)
    @layerIdIn = editObject['layer_id'][0]
    @annotationIn = JSON.parse(editObject['annotation'].to_json)
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
    #if !validate_annotation @annotationIn
    #  errMsg = "Annotation not valid and could not be updated: " + @problem
    #  p "Annotation not valid and could not be updated: #{errMsg}"
    #  render :json => { :error => errMsg },
    #         :status => :unprocessable_entity
    #else
      @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first
      #-------
      p 'just searched for this annotation: id = ' + @annotation.annotation_id
      if @annotation.nil?
        format.json { render json: nil, status: :ok }
      else
          #authorize! :update, @annotation

          if @annotation.version.nil? ||  @annotation.version < 1
            @annotation.version = 1
          end
          if !version_annotation @annotation
            errMsg = "Annotation could not be updated: " + @problem
            render :json => { :error => errMsg },
                   :status => :unprocessable_entity
          end

          if (updateLists == true)
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
                :motivation => @annotationIn['motivation'],
                :on => @annotationIn['on'],
                :resource => @annotationIn['resource'].to_json,
                :annotated_by => @annotationIn['annotatedBy'].to_json,
                :version => newVersion,
                :order_weight => @annotationIn['orderWeight']
            )
              format.html { redirect_to @annotation, notice: 'Annotation was successfully updated.' }
              format.json { render json: @annotation.to_iiif, status: 200, content_type: "application/json"}
            else
              format.html { render action: "edit" }
              format.json { render json: @annotation.errors, status: :unprocessable_entity, content_type: "application/json" }
            end
          end
      end


    #end
  end

  # DELETE /annotation/1
  # DELETE /annotation/1.json
  def destroy
    p 'in annotation_controller:destroy'

    #@ru = request.original_url   # will not work with rspec
    @ru = Rails.application.config.hostUrl  + "/annotations/#{params['id']}"
    @ru = Rails.application.config.hostUrl  + "annotations/#{params['id']}"
    #@ru = params['id'] # for rspec
    #@ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"
    request.format = "json"


    @annotation = Annotation.where(annotation_id: @ru).first
    if @annotation.nil?
      format.json { render json: nil, status: :ok }
    else
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
        #if !list_id.include?("_INACTIVE")
          @annotation_list = AnnotationList.where(list_id: list_id).first
          if @annotation_list.nil?
            #@problem = "'within' element: Annotation List " + list_id + " does not exist"
            #valid = false
          end
        end
      #end
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
    if (!@annotationIn['on']['full'].to_s.include?('/canvas/'))
      @annotation = Annotation.where(annotation_id:@annotationIn['on']['full']).first
      @canvas_id = getTargetingAnnosCanvas(@annotation)
    end
    @required_list_id = constructRequiredListId @layer_id, @canvas_id
    checkListExists @required_list_id, @layer_id, @canvas_id
  end

  def handleRequiredListMultipleOn
    p 'in HandleRequiredListMultipleOn:'
    #****************************************************
    # multiple "on's" will be an array
    #****************************************************
   # @annotationIn['on'] = '[{
   #   "@type": "oa:Annotation",
   #   "full": "http://localhost:5000/annotations/Panel_B_Chapter_26_Scene_1_1_Tibetan_Sun_Of_Faith"
   #    },
   #   {
   #   "@type": "oa:Annotation",
   #   "full": "http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
   #  }]'
    p 'What is wrong with the on_array?'
    p "@annotationIn['on']: #{@annotationIn['on']}"
    puts "\n"
    #on_array = JSON.parse(@annotationIn['on'])
    #on_array.each do |on|
    @annotationIn['on'].each do |on|
        on = JSON.parse(on.to_json)
        #===================================
        @canvas_id = on['full']
        #@canvas_id = on.full
        p "@canvas_id = #{@canvas_id}"
        if (!on['full'].to_s.include?('/canvas/'))
          #@annotation = Annotation.where(annotation_id:on['full']).first
          @annotation = Annotation.where(annotation_id:on['full']).first
          @canvas_id = getTargetingAnnosCanvas(@annotation)
        end
        p "now @canvas_id = #{@canvas_id}"
        #@canvas_id = on['full']
        @required_list_id = constructRequiredListId @layer_id, @canvas_id
        checkListExists @required_list_id, @layer_id, @canvas_id
        #====================================
    end
  end

  def constructRequiredListId layer_id, canvas_id
    #@ru = request.original_url.split('?').first
    @ru = Rails.application.config.hostUrl
    @ru += '/'   if !@ru.end_with? '/'
    #list_id = request.protocol + request.host_with_port + "/lists/" + layer_id + "_" + canvas_id # host_with_port seems to be returning varying values
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
    #if !@annotationIn.key?(:within)
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
    #p "full = #{onJSON['full']}"
    #return(inputAnno) if (inputAnno.canvas.to_s.include?("oa:SvgSelector"))
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    #p "returned anno canvas = #{targetAnnotation.canvas}"
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end


#  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    return if inputAnno.nil?
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    #p "getTargetingAnnosCanvas:                        anno_id = #{inputAnno.annotation_id}  and canvas = #{inputAnno.canvas}"
    #targetAnnotation = Annotation.where(canvas:inputAnno.canvas).first
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first
    #p "just got targetAnnotation based on that canvas: anno_id = #{targetAnnotation.annotation_id}  and canvas = #{targetAnnotation.canvas} "
    getTargetingAnnosCanvas targetAnnotation
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

  # GET /solrFeed.json
  def getAnnotationsForSolrFeed

    # replace @ru with hostUrl environment variable
    p "host url = #{Rails.application.config.hostUrl}"
    @annotation = Annotation.all
    respond_to do |format|
      solr = []
      i=0
      @annotation.each do |annotation|
        #break if i > 3
        i+=1
        solr << annotation.to_solr
      end
      solr.to_json
      format.html {render json: solr}
      format.json {render json: solr, content_type: "application/json"}
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
=begin
    respond_to do |format|
      if annotation.update_attributes(
          :on => annotation['on'].to_json
      )
        format.html { redirect_to annotation, notice: 'Annotation was successfully updated.' }
        format.json { render json: annotation.to_iiif, status: 200, content_type: "application/json"}
      else
        format.html { render action: "edit" }
        format.json { render json: annotation.errors, status: :unprocessable_entity, content_type: "application/json" }
      end
    end
=end
  end

  def getSvg
    annotation_id = params['id']
    #p "id = #{annotation_id}"
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    p "on = #{on.to_json}"
    svg = on["selector"]["value"]
    p "svg = #{svg}"
    #render json: annotation.to_iiif
    #render json: svg.to_s
    render json: on
  end

  def get_svg_path anno
    on = JSON.parse(anno.on)
    svg = on["selector"]["value"]
    svgHash = Hash.from_xml(svg)
    #puts "svgHash.svg.path.d: #{svgHash["svg"]["path"]["d"]}"
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
      #format.json {render :text => allLayers}
      #format.text {render xml: allLayers, content_type: "xml"}
      format.text {render :text => allLayers, :content_type => Mime::TEXT.to_s}
    end
  end

  def feedAnnosNoResourceWrapper
    allOrDelta = params['delta']
    allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'

    p "in controller: feedAnnosNoResourceWrapper"
    annos = CSV.generate do |csv|
      Annotation.feedAnnosNoResource csv
    end

    respond_with do |format|
      #format.csv {render :csv => annos, content_type: "application/csv"}
      format.text {render :text => annos, content_type: "application/csv"}
    end
  end

  def feedAnnosResourceOnlyWrapper
    allOrDelta = params['delta']
    allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'

    p "in controller: feedAnnosResourceOnlyWrapper"
    annos = CSV.generate do |csv|
      Annotation.feedAnnosResourceOnly csv
    end

    p "about to respond: annos = #{annos}"
    respond_with do |format|
      format.text {render :text => annos, content_type: "application/csv"}
      format.csv {render :text => annos, content_type: "application/csv"}
    end
  end

  # simple Redis test
  def doRedis
    #redis = Redis.new
    #@redis.set("royKey", "Roy's Key")
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
    lists = AnnotationList.where("list_id like ? and list_id like ?", "%#{canvas_id}%", "%/lists/%")
    #lists = AnnotationList.where("list_id like ? and list_id like ? and list_id like ?", "#{host_url_prefix}%", "%#canvas_id}%", "%/lists/%")

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
    #return @redis.get(canvas_id)
  end

  def setRedisKeys
    #annotations.lotb.yale.edu/setRedisKeys?canvas_id=http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01
    @redis = Redis.new(url: ENV["REDIS_URL"])

    @canvasKey = params['canvas_id']
    if Rails.application.config.hostUrl.end_with?("/")
      urlForRedisKey = Rails.application.config.hostUrl + "getAnnotationsViaList/?canvas_id=#{@canvasKey}"
    else
      urlForRedisKey  = Rails.application.config.hostUrl + "/getAnnotationsViaList/?canvas_id=#{@canvasKey}"
    end


    p "about to set redisKey for #{@canvasKey}"
    p urlForRedisKey = #{urlForRedisKey}"

    redisValue = open(urlForRedisKey).read
    redisValue.gsub!(/=>/,":")
    @redis.set(@canvasKey,redisValue)


    # redisValue_Panel_01 = open("http://annotations.lotb.yale.edu/getAnnotationsViaList?canvas_id=http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01").read
    # redisValue_Panel_01 = open("http://annotations.lotb.yale.edu/getAnnotationsViaList?canvas_id=http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01").read
    # redisValue_Panel_01.gsub!(/=>/,":")
    # redisValue_Panel_01 = JSON.parse(redisValue_Panel_01)
    # @redis.set("http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01",redisValue_Panel_01)

    response = '{/"redisKey/":/"' + @canvasKey + '/" set/"}'
    respond_to do |format|
      format.html { render html: response, status: :ok }
      format.json { render json: response, status: :ok }
    end
  end

end
