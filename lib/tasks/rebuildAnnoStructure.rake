namespace :rebuild_anno_structure do
  desc "rebuild annotations, lists, layers and mappings; also remap canvases and layer for Drupal environment"
  task :rebuild => :environment do
    @host = Rails.application.config.hostUrl
    puts "Current env is #{ENV['IIIF_HOST_URL']}"
    @host = "http://annotations.ten-thousand-rooms.yale.edu/" if @host.nil?
    @host += '/'   if !@host.end_with? '/'
    p "@host= #{@host}"
    count=0
    # get all annotations and set up loop
    @annotations = Annotation.all
    @annotations.each do |anno|
      @anno = anno
      count+=1
      p count.to_s + ") created_at: #{anno.created_at.to_s}"
      next if @anno.created_at.to_s.start_with?("2015")
      #p "date ok"
      next if count < 24
     # break if count > 1000
      # set up new annotation
      next if !anno.annotation_id.include?("/annotations/")
      @annotationOut = Hash.new
      @newAnnoId = construct_new_anno_id @anno.annotation_id
      @annotationOut['annotation_id'] = @newAnnoId
      @annotationOut['annotation_type'] = @anno.annotation_type
      @annotationOut['motivation'] = @anno.motivation
      @annotationOut['description'] = @anno.description
      @annotationOut['annotated_by'] = @anno.annotated_by
      @annotationOut['resource']  = @anno.resource
      @annotationOut['active'] = @anno.active
      @annotationOut['version'] = @anno.version
      # handle new canvas:
        # if it is the original canvas, then map to the new canvas and use that
        # if it not on the original canvas, then take the targeted annotation_id and re-write it for the new host variable (construct_new_anno_id)
      @currentCanvas = @anno.canvas
      next if @currentCanvas.nil?
      # if on canvas:
      if @currentCanvas.include?('/canvas/')
        @origCanvasAnno = @anno
        canvasMapping = CanvasMappingOldNew.where(old_canvas_id: @currentCanvas).first
        if canvasMapping.nil?
          p "no canvas mapping for canvas: #{@currentCanvas}"
          next
        end
        @newCanvas = canvasMapping.new_canvas_id
        p "@currentCanvas = #{@currentCanvas}"
        p "@newCanvas = #{@newCanvas}"
      else
        next if !@currentCanvas.include?("/annotations/")
        @newCanvas = construct_new_anno_id @currentCanvas
        p "#{@anno.annotation_id} targets another anno with new id:  #{@newCanvas}"
        @origCanvasAnno = getAnnoWOriginalCanvas @anno
        next if @origCanvasAnno.nil?
        p "  --- the original canvas is: :  #{@origCanvasAnno.canvas}"
      end

      # set canvas field to new canvas
      @annotationOut['canvas'] = @newCanvas

      # parse "on" field to access "on"["full"]
      onField = JSON.parse(@anno.on.gsub!(/=>/,":"))

      # set ["full"] to new canvas
      onField['full'] = @newCanvas
      @annotationOut['on'] = onField

      # determine this annotations layer and save it
      #@currentLayerId = getLayerRbld anno.annotation_id
      @currentLayerId = getLayerRbld @origCanvasAnno.annotation_id
      p "@currentLayerId = #{@currentLayerId}"
      next if @currentLayerId=="No Layer"
      # map to new layer
      layerMapping = LayerMapping.where(layer_id: @currentLayerId).first
      next if layerMapping.nil?
      @newLayerId = layerMapping.new_layer_id

      p "@newLayerId = #{@newLayerId}"

      annotationFound = Annotation.where(annotation_id: @newAnnoId).first
      if annotationFound.nil?
        # handle required list using new layer, including list_anotations_maps, annotation_lists, layer_list_maps.  Layer should already have been imported
        handleRequiredList
        p "Required lists and mappings done for: #{@newAnnoId}"
        ListAnnotationsMap.setMap @annotationOut['within'],@newAnnoId
        @annotation = Annotation.new(@annotationOut)
        @annotation.save!(options={validate: false})
      end
      # leave old records;clean in separate process based on creation date
    end
  end

#===================

  def construct_new_anno_id annotation_id
    p "construct_new_anno_id: annotation_id = #{annotation_id}"
      replaceUpTo = annotation_id.index("/annotations/") + 1
      new_anno_id = @host + annotation_id[replaceUpTo..annotation_id.length]
  end

  def getLayerRbld annotation_id
    p 'in rake getLayerRbld'
    listIds = ListAnnotationsMap.getListsForAnnotation annotation_id
    p "lists count = #{listIds.count}"
    # can assume one list for this process
    list = AnnotationList.where(list_id:listIds.first).first
    if !list.nil?
      layerIds = LayerListsMap.getLayersForList list.list_id
      # can assume one layer for this process
      layer_id = layerIds.first
    else
      layer_id = "No Layer"
    end
  end

  #=====================

  def handleRequiredList
    p 'in rake HandleRequiredList'
    if (!@newCanvas.include?('/canvas/'))
      # here I do need the original canvas
      @canvas_id = getTargetingAnnosCanvas(@anno)
      # map to new canvas now now that we have the orig
      canvasMapping = CanvasMappingOldNew.where(old_canvas_id: @canvas_id).first
      #canvasMapping = CanvasMappingOldNew.where(old_canvas_id: @origCanvasAnno.canvas).first
      if canvasMapping.nil?
        #@annotationOut['within']=''
        p "no canvas mapping for canvas: #{@currentCanvas}"
        return
      end
      @newCanvas = canvasMapping.new_canvas_id
    end
    @required_list_id =  @host + "lists/" + @newLayerId + "_" + @newCanvas
    checkListExists @required_list_id, @newLayerId, @newCanvas
  end

  def checkListExists list_id, layer_id, canvas_id
    @annotation_list = AnnotationList.where(list_id: list_id).first
    if @annotation_list.nil?
      createAnnotationListForMap(list_id, layer_id, canvas_id)
    end
    # ---
    # create within array for mapping
    withinArray = Array.new
    withinArray.push(list_id)
    withinArray
    @annotationOut['within'] = withinArray
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
    #create_list_acls_via_parent_layers @list['list_id']
    @annotation_list = AnnotationList.create(@list)
  end

# move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getTargetingAnnosCanvas inputAnno
    return if inputAnno.nil?
    p "in getTargetingAnnosCanvas: current anno_id: #{inputAnno.annotation_id} and current canvas: #{inputAnno.canvas}"
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))

    #targetAnnotation = Annotation.where(canvas:inputAnno.canvas).first
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first

    getTargetingAnnosCanvas targetAnnotation
  end

# move backwards from an annotations' target until the last (or first) targeted anno, then return this one's canvas
  def getAnnoWOriginalCanvas inputAnno
    return if inputAnno.nil?
    p "in getAnnoWOriginalCanvas: current anno_id: #{inputAnno.annotation_id} and current canvas: #{inputAnno.canvas}"
    return(inputAnno) if (inputAnno.canvas.to_s.include?('/canvas/'))

    #targetAnnotation = Annotation.where(canvas:inputAnno.canvas).first
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first

    getAnnoWOriginalCanvas targetAnnotation
  end

end

