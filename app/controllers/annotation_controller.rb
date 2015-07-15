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
    @annotationIn = JSON.parse(params['annotation'])
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
      @annotationOut['resource']  = @annotationIn.to_json
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
  def validate_annotation annotation
    valid = true
    p '@type = ' + annotation['@type'].to_s
    if !annotation['@type'].to_s.downcase!.eql? 'oa:annotation'
      @problem = "invalid '@type'"
      valid = false
    end
    if annotation['motivation'].nil?
      @problem = "missing 'motivation'"
      valid = false
    end
    if annotation['within'].nil?
      @problem = "missing 'within' element"
      valid = false
    end
    valid
  end
end
