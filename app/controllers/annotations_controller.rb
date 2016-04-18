include AclCreator

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
        format.json {render json: iiif}
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

    @annotation = Annotation.where(canvas:params['canvas_id'])
    if params['includeTargetingAnnos']== 'true'
      @annotationsOnAnnotations = getTargetingAnnos @annotation
    end

    respond_to do |format|
      annoWLayerArray = Array.new
      iiif = Array.new
      @annotation.each do |annotation|
        p " "
        p "getAnnotationsForCanvas: doing annotation: #{annotation.annotation_id}"

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
            p "getAnnotationsForCanvas: doing list: #{list_id}"
            layers = LayerListsMap.getLayersForList list_id
            # 4/7/2016
            p "layers count = #{layers.count().to_s}"
            annoWLayerHash= Hash.new
            if (layers.nil?)
              #p "layers = nil"
              #annoWLayerHash= Hash.new
              annoWLayerHash["layer_id"] = "no layer"
              annoWLayerHash["annotation"] = annotation.to_iiif
              annoWLayerArray.push(annoWLayerHash)
            else
              p "layers = NOT nil"
              layers.each do |layer_id|
                p "getAnnotationsForCanvas: doing layer: #{layer_id}"
                p " "

                annoWLayerHash= Hash.new
                annoWLayerHash["layer_id"] = layer_id
                annoWLayerHash["annotation"] = annotation.to_iiif
                annoWLayerArray.push(annoWLayerHash)
              end

              #layers.each do |layer_id|
              #  p "layer = #{layer_id}"
              #  annoWLayerHash["layer_id"] = layer_id
              #  annoWLayerHash["annotation"] = annotation.to_iiif
              #  annoWLayerArray.push(annoWLayerHash)
              #end
            end
          end
        end
      end

      format.html {render json: annoWLayerArray}
      format.json {render json: annoWLayerArray}
    end
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    p 'in show method for annotations'
    @ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"

    p "in controller_show: annotation @ru = " + @ru

    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :show, @annotation_list
    request.format = "json"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation.to_iiif }
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
      #@ru = request.original_url
      @ru = request.original_url.split('?').first
      @ru += '/'   if !@ru.end_with? '/'
      @annotation_id = @ru + SecureRandom.uuid
      @annotation_id = @ru + SecureRandom.uuid
      @annotationOut = Hash.new
      @annotationOut['annotation_id'] = @annotation_id
      @annotationOut['annotation_type'] = @annotationIn['@type']
      @annotationOut['motivation'] = @annotationIn['motivation']
      #@on = @annotationIn['on']
      #@annotationOut['on'] = @on.gsub(/=>/,":")
      @annotationOut['on'] = @annotationIn['on']
      @annotationOut['description'] = @annotationIn['description']
      @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json
      #@annotationOut['canvas']  = @annotationIn['on']['source']#.to_json
      @annotationOut['canvas']  = @annotationIn['on']['full']
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['order_weight']  = @annotationIn['orderWeight']
      @annotationOut['active'] = true
      @annotationOut['version'] = 1

      # determine the required list for this layer and canvas (this is project-specific)
      # and create as needed (if this is the first annotation for this layer/canvas)
      handleRequiredList

      ListAnnotationsMap.setMap @annotationIn['within'], @annotation_id
      create_annotation_acls_via_parent_lists @annotation_id
      @annotation = Annotation.new(@annotationOut)
      #authorize! :create, @annotation
      request.format = "json"
      p 'about to respond in create'
      respond_to do |format|
        if @annotation.save
          format.json { render json: @annotation.to_iiif, status: :created} #, location: @annotation }
        else
          format.json { render json: @annotation.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /layer/1
  # PUT /layer/1.json
  def update
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
      # rewrite the ListAnnotationsMap for this annotation: first delete, then re-write based on ['within']
      ListAnnotationsMap.deleteAnnotationFromList @annotation.annotation_id
      ListAnnotationsMap.setMap @annotationIn['within'], @annotation.annotation_id
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
          format.json { render json: @annotation.to_iiif, status: 200}
        else
          format.html { render action: "edit" }
          format.json { render json: @annotation.errors, status: :unprocessable_entity }
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
    #p 'validate: ' + annotation.inspect
    #p '@type = ' + annotation['@type'].to_s
    #p 'on = ' + annotation['on'].to_s
    #p 'resource = ' + annotation['resource'].to_s

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

  def handleRequiredList
    #@canvas_id =  @annotationIn['on']['source']
    @canvas_id =  @annotationIn['on']['full']
    @required_list_id = constructRequiredListId
    p "constructed Required List = " + @required_list_id
    checkListExists @required_list_id
  end

  def constructRequiredListId
    @ru = request.original_url.split('?').first
    @ru += '/'   if !@ru.end_with? '/'
    @ru.gsub!(/annotations/,"lists")
    list_id = @ru + @layer_id + "_" + @canvas_id
  end

  def checkListExists list_id
    #@annotation_list = AnnotationList.where(list_id: @ru).first # never finding this and was causing dupes
    @annotation_list = AnnotationList.where(list_id: list_id).first
    if @annotation_list.nil?
      createAnnotationListForMap(list_id, @layer_id, @canvas_id)
    end
    # add to within if necessary
    #if @annotation['within'].nil?
    if !@annotationIn.key?(:within)
      withinArray = Array.new
      withinArray.push(list_id)
      @annotationIn['within'] = withinArray
    else
      withinArray = @annotationIn['within'].to_arr
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

  def  getTargetingAnnos inputAnnos
    return if (inputAnnos.nil?)
    inputAnnos.each do |anno|
      p 'getTargetingAnnos: anno_id = ' + anno.annotation_id
      targetingAnnotations = Annotation.where(canvas:anno.annotation_id)
      getTargetingAnnos targetingAnnotations
      @annotation += targetingAnnotations if !targetingAnnotations.nil?
    end
  end

end
