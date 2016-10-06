include AclCreator
require "json"
require "csv"
require 'date'

class AnnotationsController < ApplicationController
  include CanCan::ControllerAdditions
  #skip_before_action :verify_authenticity_token
  #before_action :authenticate_user!
  respond_to :json, :text

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

  def getAnnotationsForCanvas
    bearerToken = ''
    bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
    #p "bearerToken = #{bearerToken}"
    if (bearerToken)
      @user = signInUserByBearerToken bearerToken
    end

    p 'request.headers["Content-Type"] = ' +  request.headers["Content-Type"] unless request.headers["Content-Type"].nil?
    request.headers["Content-Type"] = "application/json"
    p 'request.headers["Content-Type"] = ' +  request.headers["Content-Type"] unless request.headers["Content-Type"].nil?

    @annotation = Annotation.where(canvas:params['canvas_id'])
    if params['includeTargetingAnnos']== 'true'
      @annotationsOnAnnotations = getTargetingAnnos @annotation
    end

    respond_to do |format|
      annoWLayerArray = Array.new
      iiif = Array.new
      @annotation.each do |annotation|
        within = ListAnnotationsMap.getListsForAnnotation annotation.annotation_id

        #authorized = false
        authorized = true
        # TODO: turn authorization back on for next pass
=begin
        within.each do |list_id|
            # figure out if user has read permission on this list via cancan/webacl; if not do not include in returned annoarray
            @annotation_list = AnnotationList.where(:list_id => list_id).first
            if can? :show, @annotation_list
              authorized = true
            end
        end
=end
        if (authorized==true)
          #iiif.push(annotation.to_iiif)
          # return not just array of annotations but including an array of layers for each annotation as well
          lists = ListAnnotationsMap.getListsForAnnotation annotation.annotation_id
          lists.each do |list_id|
            #if (!list_id.include?('/canvas/'))
              #p "getAnnotationsForCanvas: doing list: #{list_id}"
              layers = LayerListsMap.getLayersForList list_id
              # 4/7/2016
              #p "layers count = #{layers.count().to_s}"
              annoWLayerHash= Hash
                                  .new
              if (layers.nil?)
                #p "layers = nil"
                #annoWLayerHash= Hash.new
                annoWLayerHash["layer_id"] = "no layer"
                annoWLayerHash["annotation"] = annotation.to_iiif
                annoWLayerArray.push(annoWLayerHash)
              else
                #p "layers = NOT nil"
                layers.each do |layer_id|
                  #p "getAnnotationsForCanvas: doing layer: #{layer_id}"
                  #p " "

                  annoWLayerHash= Hash.new
                  annoWLayerHash["layer_id"] = layer_id
                  annoWLayerHash["annotation"] = annotation.to_iiif
                  annoWLayerArray.push(annoWLayerHash)
                end
              end
            #end
          end
        end
      end

      p annoWLayerArray.inspect

      format.html {render json: annoWLayerArray}
      format.json {render json: annoWLayerArray, content_type: "application/json"}
      end
  end

  def getAnnotationsForCanvasViaLists
    bearerToken = ''
    p 'in getAnnotationsForCanvasViaLists: params = ' + params.inspect
    #p 'in getAnnotationsForCanvasViaLists: headers: ' + request.headers.inspect
    bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
    #p "bearerToken = #{bearerToken}"
    if (bearerToken)
      @user = signInUserByBearerToken bearerToken
    end
    lists = AnnotationList.where("list_id like ? and list_id like ?", "%#{params['canvas_id']}%", "%/lists/%")
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
    respond_to do |format|
      format.html {render json: annoWLayerArrayUniq}
      format.json {render json: annoWLayerArrayUniq, content_type: "application/json"}
    end
  end

  def getLayerFromListName listName
    match = /\/http(\S+\/layers\/\S+_h)/.match(listName)
    return if match.nil?
    layer_id = match[0]
    layer_id =layer_id[1...-2]
    layer_id = "No layer" if (layer_id.nil?)
    layer_id
  end

  # for future use
  def getAnnotationsForCanvasLayer
    if(params.has_key?(:layer_id))
      layer_id = params['layer_id']
    else
      layer_id = 'http://ten-thousand-rooms.herokuapp.com/layers/1ac0123c-1ec6-11e6-b6ba-3e1d05defe78'
    end
    #construct the list_id
    list_id = request.protocol + request.host_with_port + "/lists/" + layer_id + "_" + canvas_id
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    testParam =  '"on": {
        "@type": "oa:Annotation",
        "full": "http://annotations.tenkr.yale.edu/annotations/f96a7d52-740d-4db5-8945-bb47b3884261"
    }'.split(",")
    testParamArr =  '["on": {
        "@type": "oa:Annotation",
        "full": "http://annotations.tenkr.yale.edu/annotations/f96a7d52-740d-4db5-8945-bb47b3884261"
    }, {
        "@type": "oa:Annotation",
        "full": "http://annotations.tenkr.yale.edu/annotations/f96a7d52-740d-4db5-8945-bb47b3884262"
    }]'.split(",")

    @ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"
    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :show, @annotation_list
    request.format = "json"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation.to_iiif, content_type: "application/json" }
    end
  end

  # POST /annotation
  #
  def create
    #@annotationIn = params
    # for new params with layer_id and annotation
    @paramsIn = params
    @layer_id = @paramsIn['layer_id']
    @annotationIn = @paramsIn['annotation']

    @problem = ''
    if !validate_annotation @annotationIn
      errMsg = "Annotation record not valid and could not be saved: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @ru = request.original_url.split('?').first
      @ru += '/'   if !@ru.end_with? '/'
      @annotation_id = @ru + SecureRandom.uuid
      @annotation_id = @ru + SecureRandom.uuid
      @annotationOut = Hash.new
      @annotationOut['annotation_id'] = @annotation_id
      @annotationOut['annotation_type'] = @annotationIn['@type']
      @annotationOut['motivation'] = @annotationIn['motivation']
      @annotationOut['description'] = @annotationIn['description']
      @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json
      #TODO: consider if canvas convenience field should be set to original canvas for targeting annotations as well.
      @annotationOut['canvas']  = @annotationIn['on']['full']
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['active'] = true
      @annotationOut['version'] = 1

      # a test for multiple on's:
      #@annotationIn['on'] = '[{
      #   "@type": "oa:Annotation",
      #   "full": "http://localhost:5000/annotations/Panel_B_Chapter_26_Scene_1_1_Tibetan_Sun_Of_Faith"
      #   },
      #   {
      #   "@type": "oa:Annotation",
      #   "full": "http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
      # }]'

      @annotationOut['on'] = @annotationIn['on']
      p "@annotationIn['on'] = #{@annotationIn['on']}"

      # determine the required list for this layer and canvas (this is project-specific)
      # and create as needed (if this is the first annotation for this layer/canvas)
      # Deal with possibility of 'on' being multiple canvases (or annotations); in this case 'on' will look like an array, which will mean multiple lists
      if !@annotationIn['on'].to_s.start_with?("[")
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
    end
  end

  # PUT /annotation/1
  # PUT /annotation/1.json
  def update
    p "in update"
    @ru = request.original_url
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
    if !validate_annotation @annotationIn
      errMsg = "Annotation not valid and could not be updated: " + @problem
      p "Annotation not valid and could not be updated: #{errMsg}"
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first
      p 'just searched for this annotation: id = ' + @annotation.annotation_id

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
  end

  # DELETE /annotation/1
  # DELETE /annotation/1.json
  def destroy
    p 'in annotation_controller:destroy'

    @ru = request.original_url   # will not work with rspec
    #@ru = params['id'] # for rspec
    #@ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"
    request.format = "json"

    @annotation = Annotation.where(annotation_id: @ru).first
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
    on_array = JSON.parse(@annotationIn['on'])
    on_array.each do |on|
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
        @required_list_id = constructRequiredListId @layer_id, @canvas_id
        checkListExists @required_list_id, @layer_id, @canvas_id
        #====================================
    end
  end

  def constructRequiredListId layer_id, canvas_id
    @ru = request.original_url.split('?').first
    @ru += '/'   if !@ru.end_with? '/'
    #list_id = request.protocol + request.host_with_port + "/lists/" + layer_id + "_" + canvas_id # host_with_port seems to be returning varying values
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

#  move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    if inputAnno.nil! return
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    #p "getTargetingAnnosCanvas:                        anno_id = #{inputAnno.annotation_id}  and canvas = #{inputAnno.canvas}"
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
    p "id = #{annotation_id}"
    annotation = Annotation.where(annotation_id: annotation_id).first
    on = JSON.parse(annotation.on)
    p "on = #{on.to_json}"
    svg = on["selector"]["value"]
    p "svg = #{svg}"
    #render json: annotation.to_iiif
    #render json: svg.to_s
    render json: on
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


  def feedAnnosNoResource
    #resourceMode = params['resourceMode']
    #resourceMode = 'none' if resourceMode.nil?
    allOrDelta = params['delta']
    allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'

    if allOrDelta == 'all'
      @annotation = Annotation.all
    else
      @annotation = Annotation.where(['updated_at > ?', DateTime.now-allOrDelta.to_i.days])
    end
    annos = CSV.generate do |csv|
      headers = "annotation_id, annotation_type, context, on, canvas, motivation,layers"
      csv << [headers]
      @annotation.each do |anno|
        feedOn = ''
        @canvas_id = ''

        # check anno.onis valid
        if !anno.on.start_with?('{') && !anno.on.start_with?('[')
          next
        end
        if anno.canvas.nil?
          next
        end

        #onJSON = JSON.parse(anno.on.gsub(/=>/,":"))

        if !anno.on.start_with?('[')

          #if !onJSON['full'].include?("/canvas/")
          if !anno.canvas.include?("/canvas/")
            # if not on a canvas it will be on another annotation, so include 'full'
            #feedOn = onJSON['full']
            feedOn = anno.canvas
          end

          #@canvas_id = onJSON['full']
          @canvas_id = anno.canvas
          # get original canvas
          #if (!onJSON['full'].include?('/canvas/'))
          if (!anno.canvas.include?('/canvas/'))
            #@annotation = Annotation.where(annotation_id:onJSON['full']).first
            @annotation = Annotation.where(annotation_id:anno.canvas).first
            if !@annotation.nil?
              @canvas_id = getTargetingAnnosCanvas(@annotation)
            end
          end

        end
        layers = anno.getLayersForAnnotation  anno.annotation_id
        csv << [anno.annotation_id, anno.annotation_type, "http://iiif.io/api/presentation/2/context.json", feedOn, @canvas_id, anno.motivation, layers]
      end

    end
    respond_with do |format|
      format.json {render :text => annos}
      format.text {render :text => annos}
    end
  end

  def feedAnnosResourceOnly
    allOrDelta = params['delta']
    allOrDelta = "all" if allOrDelta.nil? or allOrDelta == '0'

    if allOrDelta == 'all'
      @annotation = Annotation.all
    else
      @annotation = Annotation.where(['updated_at > ?', DateTime.now-allOrDelta.to_i.days])
    end

    annos = CSV.generate do |csv|
      headers = "annotation_id, resource_id, type, format, chars"
      csv << [headers]
      @annotation.each do |anno|
        resourceJSON = JSON.parse(anno.resource)
        resourceJSON.each do |resource|
          resource_id = anno.annotation_id + "_" + SecureRandom.uuid
          csv << [anno.annotation_id, resource_id, resource['@type'], resource['format'], resource['chars']]
        end
      end
    end
    respond_with do |format|
      format.json {render :text => annos}
      format.text {render :text => annos}
    end
  end

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

end
