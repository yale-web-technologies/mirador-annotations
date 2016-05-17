namespace :checkData do

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
      p 'check: search for canvas failed!'
      noCanvas = true
      return "No Canvas!"
    end
    p "check: anno_id = #{inputAnno.annotation_id} canvas = #{inputAnno.canvas} and noCanvas = #{noCanvas}"
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

end