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
        p "processing: #{count.to_s}) #{anno.annotation_id}"
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
  task :addBB_XYWH => ["db:prod:set_prod_env", :environment] do
    @annotations = Annotation.all.order("id")
      count = 0
      xywh = ''
      @annotations.each do |anno|
        count += 1
        #break if count > 20
        p anno.annotation_id
        #p "on: #{anno.on}"

        #next if anno.annotation_id.include?("/annotations/Panel_A_Chapter_1")
        next unless
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_1") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_2") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_3") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_4") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_5") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_6") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_7") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_8") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_9") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_10") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_11") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_12") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_13") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_14") ||
            anno.annotation_id.include?("/annotations/Panel_A_Chapter_15") ||
            anno.annotation_id.include?("annotations/Panel_A_Chapter_16")  ||
            anno.annotation_id.include?("annotations/Panel_A_Chapter_17")  ||
            anno.annotation_id.include?("annotations/Panel_A_Chapter_18")  ||
            anno.annotation_id.include?("annotations/Panel_A_Chapter_19")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_19")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_20")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_21")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_22")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_23")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_24")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_25")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_26")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_27")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_28")  ||
            anno.annotation_id.include?("annotations/Panel_B_Chapter_29")

        svgAnno = anno

        if anno.on.include?("oa:SvgSelector")
          # get svgpath from "d" attribute in the svg selector value
          svg_path = ''
          svg_path = get_svg_path svgAnno
          if svg_path!=''
            p "svg_path: #{svg_path}"
            svg_path.gsub!(/<g>/,'')
            p "svg_path(1,30): #{svg_path[0..30]}"
            firstComma = svg_path.index(',')
            p "firstComma = #{firstComma.to_s}"
            svg_x = svg_path[1..firstComma-1].to_i + 5000
            #xywh = Annotation.get_xywh_from_svg svg_path,31000,10000 if svg_path!=''  # 16000 seems a good medium
            xywh = Annotation.get_xywh_from_svg svg_path,svg_x,10000 if svg_path!=''  # 16000 seems a good medium
            p "svg: #{xywh}"
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
    begin
      on = anno.on.gsub!(/=>/,":")
      onJSON = JSON.parse(on)
      svg = onJSON["selector"]["value"]
    rescue
        p 'error json-parsing annotation on'
        svg_path = ''
    else
      begin
        svgHash = Hash.from_xml(svg)
      rescue
        p 'error creating svg hash from json-parsed anno'
        svg_path = ''
      else
        begin
          svg_path = svgHash["svg"]["path"]["d"]
        rescue
          p "svgHash parsing d for #{anno.annotation_id}: svg_path: #{svg_path} failed"
          svg_path = ''
        end
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

  namespace :db do
    namespace :prod do
      desc "Custom dependency to set prod environment"
      task :set_prod_env do # Note that we don't load the :environment task dependency
        Rails.env = "production"
      end
    end
  end

end