require 'securerandom'
class AnnotationController < ApplicationController
  skip_before_action :verify_authenticity_token
  respond_to :html, :json

  # GET /list
  # GET /list.json
  def index
    @annotation = Annotation.all
    respond_to do |format|
      format.html #index.html.erb
      #format.json { render json: @annotation }
      iiif = []
      @annotation.each do |annotation|
        iiif << annotation.to_iiif
      end
      iiif.to_json
      format.json {render json: iiif}
    end
  end

  # GET /annotation/1
  # GET /annotation/1.json
  def show
    @ru = request.original_url
    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :show, @annotation_list
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @annotation.to_iiif }
    end
  end

  # POST /annotation
  # POST /annotation.json
  def create
    @annotationIn = JSON.parse(params.to_json)
    @problem = ''
    if !validate_annotation @annotationIn
      errMsg = "Annotation record not valid and could not be saved: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    else
      @ru = request.original_url
      @ru += '/'   if !@ru.end_with? '/'
      @annotation_id = @ru + SecureRandom.uuid
      @annotation_id = @ru + SecureRandom.uuid
      @annotationOut = Hash.new
      @annotationOut['annotation_id'] = @annotation_id
      @annotationOut['annotation_type'] = @annotationIn['@type']
      @annotationOut['motivation'] = @annotationIn['motivation']
      @annotationOut['on'] = @annotationIn['on']
      @annotationOut['canvas'] = @annotationIn['canvas']
      @annotationOut['label'] = @annotationIn['label']
      @annotationOut['description'] = @annotationIn['description']
      @annotationOut['annotated_by'] = @annotationIn['annotatedBy'].to_json
      #@annotationOut['resource']  = @annotationIn.to_json
      @annotationOut['resource']  = @annotationIn['resource'].to_json
      @annotationOut['active'] = true
      @annotationOut['version'] = 1
      ListAnnotationsMap.setMap @annotationIn['within'], @annotation_id
      @annotation = Annotation.new(@annotationOut)
      #authorize! :create, @annotation
      respond_to do |format|
        if @annotation.save
          format.html { redirect_to @annotation, notice: 'Annotation was successfully created.' }
          format.json { render json: @annotation.to_iiif, status: :created} #, location: @annotation }
        else
          format.html { render action: "new" }
          format.json { render json: @annotation.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /layer/1
  # PUT /layer/1.json
  def update
    @annotationIn = JSON.parse(params.to_json)
    @problem = ''
    if !validate_annotation @annotationIn
      errMsg = "Annotation not valid and could not be updated: " + @problem
      render :json => { :error => errMsg },
             :status => :unprocessable_entity
    end

    @annotation = Annotation.where(annotation_id: @annotationIn['@id']).first
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

  # DELETE /annotation/1
  # DELETE /annotation/1.json
  def destroy
    @ru = request.original_url
    @annotation = Annotation.where(annotation_id: @ru).first
    #authorize! :delete, @annotation
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
    if annotation['on'].nil?
      @problem = "missing 'on' element"
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
