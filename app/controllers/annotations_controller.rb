include AclCreator
require "json"

class AnnotationsController < ApplicationController
  include CanCan::ControllerAdditions
  #skip_before_action :verify_authenticity_token
  #before_action :authenticate_user!
  respond_to :json

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
          p annotation.to_iiif
        end
        iiif.to_json
        format.html {render json: iiif}
        format.json {render json: iiif, content_type: "application/json"}
      end
    end

  def getAnnotationsForCanvas
    bearerToken = ''
    p 'in getAnnotationsForCanvas: params = ' + params.inspect
    p 'in getAnnotationsForCanvas: headers: ' + request.headers.inspect
    bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
    #p "bearerToken = #{bearerToken}"
    if (bearerToken)
      @user = signInUserByBearerToken bearerToken
    end

    p 'request.headers["Content-Type"] = ' +  request.headers["Content-Type"] unless request.headers["Content-Type"].nil?
    request.headers["Content-Type"] = "application/json"
    p 'request.headers["Content-Type"] = ' +  request.headers["Content-Type"] unless request.headers["Content-Type"].nil?
    #response.headers["Content-Type"] = "application/json"

    @annotation = Annotation.where(canvas:params['canvas_id'])
    if params['includeTargetingAnnos']== 'true'
      @annotationsOnAnnotations = getTargetingAnnos @annotation
      p 'calling getTargetingAnnos'
    end

    respond_to do |format|
      annoWLayerArray = Array.new
      iiif = Array.new
      @annotation.each do |annotation|
        #p " "
        #p "getAnnotationsForCanvas: doing annotation: #{annotation.annotation_id}"
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
              annoWLayerHash= Hash.new
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
    p "lists found for bv11: #{lists.count}"
    annoWLayerArray = Array.new
    lists.each do |list|
      layer_id = getLayerFromListName list.list_id
      if !layer_id.nil?
        annotations = ListAnnotationsMap.getAnnotationsForList list.list_id
        annotations.each do |annotation|
          annoWLayerHash= Hash.new
          annoWLayerHash["layer_id"] = layer_id
          annoWLayerHash["annotation"] = annotation.to_iiif
          annoWLayerArray.push(annoWLayerHash)
        end
        puts annoWLayerArray.inspect
      end
    end
    respond_to do |format|
      format.html {render json: annoWLayerArray}
      format.json {render json: annoWLayerArray, content_type: "application/json"}
    end
  end

  def getLayerFromListName listName
    p "***** getLayerFromListName: listName = #{listName}"
    match = /\/http(\S+\/layers\/\S+_h)/.match(listName)
    return if match.nil?
    layer_id = match[0]
    layer_id =layer_id[1...-2]
    puts "***** getLayerFromListName: layer_id = #{layer_id}"
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
    p "gAFCL: #{list_id}"
  end


  # GET /annotation/1
  # GET /annotation/1.json
  def show
    p 'in show method for annotations'

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

    puts "testParam.kind_of?testParam.kind_of?(testParam) = #{testParam.kind_of?(Array)}"
    puts "testParamArr.kind_of?testParam.kind_of?(testParam) = #{testParamArr.kind_of?(Array)}"
    puts ''




    @ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"

    p "in controller_show: annotation @ru = " + @ru

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

      # test multiple on:
      #@annotationIn['on'] = '"on": [ {
      #"@type": "oa:Annotation",
      #"full": "http://annotations.tenkr.yale.edu/annotations/f96a7d52-740d-4db5-8945-bb47b3884261"
      # },
      #  {
      #    "@type": "oa:Annotation",
      #    "full": "http://annotations.tenkr.yale.edu/annotations/f96a7d52-740d-4db5-8945-bb47b3884262"
      # } ]'

      @annotationOut['on'] = @annotationIn['on']
      @annotationOut['description'] = @annotationIn['description']
      @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json
      #TODO: consider if canvas convenience field should be set to original canvas for targeting annotations as well.
      @annotationOut['canvas']  = @annotationIn['on']['full']
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['order_weight']  = @annotationIn['orderWeight']
      @annotationOut['active'] = true
      @annotationOut['version'] = 1

      # determine the required list for this layer and canvas (this is project-specific)
      # and create as needed (if this is the first annotation for this layer/canvas)
      # TODO: this could be configurable by defining a profile per deployment
      handleRequiredList
      saveOn = @annotationIn['on']
      #handleRequiredListMultipleOn  # temp
      @annotationOut['on'] = saveOn

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
    @annotationIn = JSON.parse(params.to_json)
    @problem = ''
    if !validate_annotation @annotationIn
      errMsg = "Annotation not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      #@annotation = Annotation.where(annotation_id: @annotationIn['annotation_id']).first
      @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first
      p 'just searched for this annotation: id = ' + @annotation.annotation_id.to_s

      #authorize! :update, @annotation

      if @annotation.version.nil? ||  @annotation.version < 1
        @annotation.version = 1
      end
      if !version_annotation @annotation
        errMsg = "Annotation could not be updated: " + @problem
        render :json => { :error => errMsg },
               :status => :unprocessable_entity
      end

      #comment map handling below until we receive layer and ['within'] from caller
      #ListAnnotationsMap.deleteAnnotationFromList @annotation.annotation_id
      #ListAnnotationsMap.setMap @annotationIn['within'], @annotation.annotation_id

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

  # PUT /annotation/1
  # PUT /annotation/1.json
  def updateTest
    p "in updateTest"
    @ru = request.original_url

    p "params = #{params}"
    updateLists = false
    editObject = JSON.parse(params.to_json)
    if editObject['@id']
      p "editObject['@id'] = #{editObject['@id']}"
      @annotationIn = editObject
    else if editObject['annotation']
           p "editObject['layer_id'] = #{editObject['layer_id'][0]}"
           @annotationIn = JSON.parse(editObject['annotation'].to_json)
           new_layer_id = editObject['layer_id'][0]
           updateLists = true
         end
    end
    #@annotationIn = JSON.parse(params.to_json)

    @problem = ''
    if !validate_annotation @annotationIn
      errMsg = "Annotation not valid and could not be updated: " + @problem
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
        list_id =  constructRequiredListId new_layer_id, @annotation.canvas
        canvas_id = getTargetingAnnosCanvas(@annotation)
        p "updating lists: constructed list = #{list_id}"
        checkListExists list_id, new_layer_id, canvas_id
        ListAnnotationsMap.deleteAnnotationFromList @annotation.annotation_id
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
        @annotation_list = AnnotationList.where(list_id: list_id).first
        if @annotation_list.nil?
          @problem = "'within' element: Annotation List " + list_id + " does not exist"
          valid = false
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
    @canvas_id =  @annotationIn['on']['full']

    if (!@annotationIn['on']['full'].to_s.include?('/canvas/'))
      @annotation = Annotation.where(annotation_id:@annotationIn['on']['full']).first
      p "in handleRequireList: annotation_id = #{@annotation.annotation_id}"
      # comment out until list_annos_maps is straightened out 5/16/16
      @canvas_id = getTargetingAnnosCanvas(@annotation)
    end

    @required_list_id = constructRequiredListId @layer_id, @canvas_id
    p "constructed Required List = " + @required_list_id
    checkListExists @required_list_id, @layer_id, @canvas_id

  end

  def handleRequiredListMultipleOn
    # handle multiple ['on']['full']'s: if there are multiples put the body of this def in a loop
    #
    p 'in HandleRequiredListMultipleOn'

    #****************************************************
    # manipulate "on" to test multiples
    #****************************************************
   # @annotationIn['on'] = '[{
   #   "@type": "oa:Annotation",
   #   "full": "http://localhost:5000/annotations/Panel_B_Chapter_26_Scene_1_1_Tibetan_Sun_Of_Faith"
   #    },
   #   {
   #   "@type": "oa:Annotation",
   #   "full": "http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01"
   #  }]'
    @annotationOut['on'] = @annotationIn['on']

    on_array = JSON.parse(@annotationIn['on'])
     on_array.each do |on|
        on = JSON.parse(on.to_json)
        p "should I target? on['full'] = #{on['full']}"
        @canvas_id = on['full']
        if (!on['full'].include?('/canvas/'))
          p 'am targeting'
          @annotation = Annotation.where(annotation_id:on['full']).first
          @canvas_id = getTargetingAnnosCanvas(@annotation)
        end

        @required_list_id = constructRequiredListId @layer_id, @canvas_id
        p "constructed Required List = " + @required_list_id
        checkListExists @required_list_id, @layer_id, @canvas_id
     end
  end

  def constructRequiredListId layer_id, canvas_id
    @ru = request.original_url.split('?').first
    @ru += '/'   if !@ru.end_with? '/'
    list_id = request.protocol + request.host_with_port + "/lists/" + layer_id + "_" + canvas_id
  end

  def checkListExists list_id, layer_id, canvas_id
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
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    #p "getTargetingAnnosCanvas:                        anno_id = #{inputAnno.annotation_id}  and canvas = #{inputAnno.canvas}"
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first
    #p "just got targetAnnotation based on that canvas: anno_id = #{targetAnnotation.annotation_id}  and canvas = #{targetAnnotation.canvas} "
    getTargetingAnnosCanvas targetAnnotation
  end

end
