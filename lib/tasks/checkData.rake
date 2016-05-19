namespace :checkData do

  #@ru = "http://localhost:5000"
  #@ru = "http://mirador-annotations-lotb-stg.herokuapp.com"
  #@ru = "http://mirador-annotations-lotb.herokuapp.com"
  #@ru = "http://annotations.tenkr.yale.edu"
  @ru = "http://mirador-annotations-tenkr-stg.herokuapp.com"

  desc "checks annotation data to ensure all targeting annotations (not on canvas) ultimately refer to a canvas-bound annotation"
  task :annotationGetOrigCanvas => :environment do
    @annotations = Annotation.all
    @annotations.each do |annotation|
      puts "loop before check: annotation: #{annotation.annotation_id}"
      canvas  = getTargetingAnnosCanvas annotation,false
      puts "loop after check: annotation: #{annotation.annotation_id}  ==> canvas: #{canvas}"
      puts
    end
  end

  def getTargetingAnnosCanvas inputAnno, noCanvas
   # noCanvas = false;
    if (!inputAnno.present? || noCanvas == true)
      p '    getToCanvas: search for canvas failed!'
      noCanvas = true
      return "No Canvas!"
    end
    p "    getToCanvas: anno_id = #{inputAnno.annotation_id} canvas = #{inputAnno.canvas}" # and noCanvas = #{noCanvas}"
    return(inputAnno.canvas) if (inputAnno.canvas.to_s.include?('/canvas/'))
    targetAnnotation = Annotation.where(annotation_id:inputAnno.canvas).first
    getTargetingAnnosCanvas targetAnnotation, noCanvas
  end

  #==========================================================================

  desc "gets all annos that target another anno"
  task :annotationGetTargetingAnnos => :environment do
    @annotations = Annotation.all
    allAnnos  = getTargetingAnnos @annotations
    allAnnos.each do |anno|
      puts "getTargetingAnnoLoop: annotation_id: #{anno.annotation_id} and canvas = #{anno.canvas}"
      puts
    end
  end

  def getTargetingAnnos inputAnnos
    return if (inputAnnos.nil?)
    inputAnnos.each do |anno|
      #p "getTargetingAnnos: anno_id = #{anno.annotation_id} and canvas = #{anno.canvas}"
      targetingAnnotations = Annotation.where(canvas:anno.annotation_id)
      getTargetingAnnos targetingAnnotations
      @annotations += targetingAnnotations if !targetingAnnotations.nil?
    end
  end
  #==========================================================================

  desc "gets all annos that target another anno"
  # this task assumes one layer for an annotation for purposes of creating required list of layer_id_canvas_id
  task :listAnnoMapsCheckAndFix => :environment do
    @annotations = Annotation.all
    @annotations.each do |anno|
      if (!anno.canvas.to_s.include?('/canvas/'))
        p "anno_id = #{anno.annotation_id} AND canvas = #{anno.canvas}"
        # Get Canvas
        canvas  = getTargetingAnnosCanvas anno,false
        p "original canvas = #{canvas}"
        # Get layer
        annoLayers = getAnnosLayers anno
        layer_id = annoLayers[0]
        p "layer = #{layer_id}"
        # construct required list url
        required_list_id = constructRequiredListId layer_id, canvas
        p "required list = #{required_list_id}"

        # if required_list_id does not exist create it and a mapping record to the layer
        @annotation_list = AnnotationList.where(list_id: required_list_id).first
        if @annotation_list.nil?
          createAnnotationListForMap(required_list_id, layer_id, canvas)
          p "required list: #{required_list_id} created"
        else
          p "required list: #{@annotation_list.list_id}, #{@annotation_list.created_at} exists"
        end
        # if record does not exist for this annotation in list_annotations_maps create it
        within = Array.new
        within.push(required_list_id)
        ListAnnotationsMap.setMap within, anno.annotation_id
        puts
      end
    end
  end

  def getAnnosLayers annotation
    annoWLayerArray = Array.new
    lists = ListAnnotationsMap.getListsForAnnotation annotation.annotation_id
    lists.each do |list_id|
      #p "getAnnosLayers: doing list: #{list_id}"
      layers = LayerListsMap.getLayersForList list_id
      #p "layers count = #{layers.count().to_s}"
      annoWLayerHash= Hash.new
      if (!layers.nil?)
        layers.each do |layer_id|
          annoWLayerArray.push(layer_id)
        end
      end
    end
    annoWLayerArray
  end

  def constructRequiredListId layer_id, canvas_id
    if (!layer_id=='')
      list_id = @ru +"/lists/"+ layer_id + "_" + canvas_id
    else
      list_id = @ru + "/lists/" + "_" + canvas_id
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

    #create_list_acls_via_parent_layers @list['list_id']
    @annotation_list = AnnotationList.create(@list)
  end

end