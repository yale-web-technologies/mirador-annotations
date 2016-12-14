namespace :loadAnnotationsToSolr do

  desc "load Solr documents from all annotations"
  task :solrLoadAnnos => :environment do
    @annotation = Annotation.all
    annos = CSV.generate do |csv|
      headers = "annotation_id, annotation_type, context, on, canvas, motivation,layers,bb_xywh"
      csv << [headers]

      count = 0
      @annotation.each do |anno|
        count += 1
        #break if count > 20
        #p "processing: #{count.to_s}) #{anno.annotation_id}"
        svgAnno = anno
        feedOn = ''
        @canvas_id = ''

        # check anno.on and canvas
        next if !anno.on.start_with?('{') && !anno.on.start_with?('[')
        next if anno.canvas.nil?

        # if this anno has no svg, then get the original targeted anno to send to get_svg_path
        #if !anno.on.include?("oa:SvgSelector")
        #  svgAnno = getTargetedAnno(anno)
          #p "svgAnno: #{svgAnno.annotation_id}"
        #end

        if !anno.on.start_with?('[')
          if !anno.canvas.include?("/canvas/")
             feedOn = anno.canvas
             feedOn = anno.canvas
             # get original canvas
             @annotation = Annotation.where(annotation_id:anno.canvas).first
             if !@annotation.nil?
               @canvas_id = getTargetingAnnosCanvas(@annotation)
             end
          end
          @canvas_id = anno.canvas
        end

        #first get svgpath from "d" attribute in the svg selector value
        #svg_path = ''
        #svg_path = get_svg_path svgAnno
        #xywh = Annotation.get_xywh_from_svg svg_path if svg_path!=''
        xywh = Annotation.order_weight
        layers = anno.getLayersForAnnotation  anno.annotation_id

        # just write to a file and download it
        csv << [anno.annotation_id, anno.annotation_type, "http://iiif.io/api/presentation/2/context.json", feedOn, @canvas_id, anno.motivation, layers, xywh]
        puts anno.annotation_id + "," + anno.annotation_type + "," + "http://iiif.io/api/presentation/2/context.json" + "," + feedOn + "," +  @canvas_id + "," + anno.motivation + "," + layers.to_s + "," + xywh

      end
      #puts annos
    end
  end

  desc "add BoundingBox x,y height and width to annotations"
  task :addBB_XYWH => :environment do
    @annotations = Annotation.all
      count = 0
      xywh = ''
      @annotations.each do |anno|
        count += 1
        #break if count > 20
        #next if anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_1_") ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_2_")  ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_3_") ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_4") ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_5")  ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_6")  ||
        #    anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_7")

        #next unless
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_8") ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_10")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_11")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_12") ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter13") ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter14")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter15")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter16")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter17")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter18")  ||
        #        anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_19")

        #next if !anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_6_Scene_15") && !anno.annotation_id.start_with?("http://localhost:5000/annotations/Panel_A_Chapter_6_Scene_16")

        svgAnno = anno

        if anno.on.include?("oa:SvgSelector")
          # get svgpath from "d" attribute in the svg selector value
          svg_path = ''
          svg_path = get_svg_path svgAnno
          if svg_path
            svg_path.gsub!(/<g>/,'')
            xywh = Annotation.get_xywh_from_svg svg_path,17000,17000 if svg_path!=''
            p "svg: #{xywh}"
            #if xywh == "-1,-1,1,1"
            #  xywh = Annotation.get_xywh_from_svg svg_path,18000,18000 if svg_path!=''
            #end
          end
        #else
        #  p "no svg: #{xywh}"
        #  #svgAnno = getTargetedAnno(anno)
        end

        # update annotation here
        anno.update_attributes(:service_block => xywh)
        p "processed: #{count.to_s}) #{anno.annotation_id}: #{xywh}"
      end
  end

  def get_svg_path anno
    on = JSON.parse(anno.on)
    svg = on["selector"]["value"]
    #svg.gsub!(/svg' d/,"svg'> d") if svg.include?("path xmlns='http://www.w3.org/2000/svg' d")
    begin
      svgHash = Hash.from_xml(svg)
    rescue
      svg_path = ''
    else
      begin
        svg_path = svgHash["svg"]["path"]["d"]
      rescue
        p "svgHash failed for #{anno.annotation_id}: svg_path: #{svg_path}"
        svg_path = ''
      end
    end
  end

  # for lotb
  def getTargetedAnno inputAnno
    return if inputAnno.nil?
    onN = inputAnno.on
    #p "annotationId = " + inputAnno.annotation_id
    #p "onN = " + onN
    #p ""
    onN = onN.gsub!(/=>/,':') if onN.include?("=>")
    #p "onN now = " + onN.to_s
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end

end