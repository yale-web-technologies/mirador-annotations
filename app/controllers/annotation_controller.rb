include AclCreator

class AnnotationController < ApplicationController
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

  def CORS_preflight
    p "CORS_preflight: request from: #{request.original_url}"
    p 'CORS_preflight: ' + request.headers.inspect
    headers['Access-Control-Allow-Origin'] = "*"
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def getAnnotationsForCanvas
    bearerToken = ''
    p 'in getAnnotationsForCanvas: params = ' + params.inspect
    p 'in getAnnotationsForCanvas: headers: ' + request.headers.inspect
    bearerToken = request.headers["bearer-token"] #user is logged in and has a bearer token
    p "bearerToken = #{bearerToken}"
    if (bearerToken)
      @user = signInUserByBearerToken bearerToken
    end
    @annotation = Annotation.where(canvas:params['canvas_id'])
    respond_to do |format|
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

        authorized = true

        if (authorized==true)
          iiif.push(annotation.to_iiif)
        end
      end
      p iiif.inspect
      #format.html {render json: iiif.to_json}
      #format.json {render json: iiif.to_json}
      format.html {render json: iiif}
      format.json {render json: iiif}
    end
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    p 'in show method for annotations'
    @ru = request.protocol + request.host_with_port + "/annotations/#{params['id']}"
    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :show, @annotation_list
    request.format = "json"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation.to_iiif }
    end
  end

  # POST /annotation
  # POST /annotation.j\q
  #
  #
  # son
  def create
    #@annotationIn = JSON.parse(params.to_json)
    #@annotationIn = params.to_json    # ng
    @annotationIn = params
    p "in annotation_controller:create: @annotationIn stringified = " + params.to_json

    @problem = ''
    p 'going to validation'
    if !validate_annotation @annotationIn
      errMsg = "Annotation record not valid and could not be saved: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      p 'thru validation'
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
      @annotationOut['canvas']  = @annotationIn['on']['source']#.to_json
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['active'] = true
      @annotationOut['version'] = 1
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

    p 'In annotation_controller:update  params = ' + params.inspect

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
            :version => newVersion
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

    p 'annotation_controller:destroy  params = ' + params.inspect
    request.format = "json"

    p "about to fetch for delete: #{@ru}"
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
    #annotation = JSON.parse(annotation)
    p 'validate: ' + annotation.inspect
    p '@type = ' + annotation['@type'].to_s
    p 'on = ' + annotation['on'].to_s
    p 'resource = ' + annotation['resource'].to_s

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



end
