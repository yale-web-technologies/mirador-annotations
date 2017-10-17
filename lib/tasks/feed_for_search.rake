require 'csv'
require 'aws-sdk-rails'
namespace :feed_for_search do

  desc "add BoundingBox x,y height and width to annotations"
  task :bounding_boxes => [:environment] do
    canvas_annos, anno_annos = group_annotations(Annotation.where(active: true))

    canvas_annos.each do |annotation|
      begin
        load_bounding_box(annotation)
      rescue Interrupt
        raise
      rescue Exception => e
        puts "ERROR load_bounding_box failed for annotation #{annotation.annotation_id} - #{e.inspect}"
      end
    end

    anno_annos.each do |annotation|
      canvas_anno = Annotation.find_target_annotations_on_canvas(annotation).first

      if canvas_anno
        annotation.service_block = canvas_anno.service_block
        annotation.save
        puts "A: #{annotation.annotation_id} [#{annotation.service_block}]"
      else
        puts "ERROR couldn't find canvas annotation from #{annotation.annotation_id}"
      end
    end
  end

  desc 'write csv for AnnosNoResource to a file'
  task :annos_no_resource => [:environment] do  |t, args|
      feeder = Export::SearchFeed.new
      CSV.open('AnnosNoResource.csv', 'w') do |csv|
        rows = feeder.feed_annotations_no_resource
        rows.each do |row|
          csv << row
        end
      end

      filename = 'AnnosNoResource.csv'
      s3 = Remote::S3Proxy.new
      s3.upload_file(filename, filename)
    end

  desc 'write csv for AnnosResourceOnly to a file'
  task :annos_resource_only => [:environment] do  |t, args|
    feeder = Export::SearchFeed.new
    CSV.open('AnnosResourceOnly.csv', 'w') do |csv|
      rows = feeder.feed_annotations_resource_only
      rows.each do |row|
        csv << row
      end
    end

    filename = 'AnnosResourceOnly.csv'
    s3 = Remote::S3Proxy.new
    s3.upload_file(filename, filename)
  end

  def group_annotations(annotations)
    canvas_annos = []
    anno_annos = []

    annotations.each do |anno|
      is_on_canvas =  IIIFAdapter::Anno.new(anno).targets
        .map {|target| IIIF::Target.is_canvas(target) }
        .include?(true)
      if is_on_canvas
        canvas_annos << anno
      else
        anno_annos << anno
      end
    end

    [canvas_annos, anno_annos]
  end

  def load_bounding_box(annotation)
    xywh = ''
    max_width = 30000
    max_height = 16000

    targets = IIIFAdapter::Anno.new(annotation).targets.select do |target|
      IIIF::Target.is_canvas(target)
    end

    if targets.empty?
      puts "ERROR: annotation #{annotation.annotation_id} doesn't have a valid canvas target"
      return ''
    end

    target = targets.first

    if target['selector'] && target['selector']['@type'] == 'oa:SvgSelector'
      # get svgpath from "d" attribute in the svg selector value
      svg_paths = get_svg_paths(target['selector']['value'])
      unless svg_paths.empty?
        #p "svg_path: #{svg_path}"
        #svg_path.gsub!(/<g>/,'')
        #p "svg_path(1,30): #{svg_path[0..30]}"
        firstComma = svg_paths[0].index(',')
        #p "firstComma = #{firstComma.to_s}"
        svg_x = svg_paths[0][1..firstComma-1].to_i + 5000
        #xywh = Annotation.get_xywh_from_svg svg_paths,svg_x,10000
        xywh = Annotation.get_xywh_from_svg(svg_paths, max_width, max_height)
        #p "svg: #{xywh}"
      end
    else
      puts "ERROR invalid target #{target.inspect} for annotation #{annotation.annotation_id}"
    end

    # update annotation here
    annotation.update_attributes(:service_block => xywh)
    puts "C: #{annotation.annotation_id} [#{annotation.service_block}]"
  end

  def get_svg_paths(svg)
    # dStart =  svg.index('d=') + 2
    # dEnd =  svg.index('data-paper-data') - 1
    # svg_path =svg[dStart..dEnd]

    svg_paths = []

    svg.scan(/\Wd=["']([^"']*)['"]/) do |match|
      svg_paths << match[0]
    end

    # begin
    #   svg_hash = Hash.from_xml(svg)
    # rescue
    #   p 'error creating svg hash from json-parsed anno'
    #   p "svg = #{svg.to_s}"
    #   svg_path = ''
    # else
    #   begin
    #     svg_path = svg_hash["svg"]["path"]["d"]
    #   rescue Exception => e
    #     p "svgHash parsing failed for svg_path: #{svg} - #{e.inspect}"
    #     svg_path = ''
    #   end
    # end
    svg_paths
  end

  def getTargetedAnno inputAnno
    #return if inputAnno.nil?
    p "in Rake:getTargetedAnno: annoId = #{inputAnno.annotation_id}"
    onN = inputAnno.on
    p "onN = " + onN
    p ""
    onN = onN.gsub!(/=>/,':') if onN.include?("=>")
    p "onN now = " + onN.to_s
    onJSON = JSON.parse(onN)
    targetAnnotation = Annotation.where(annotation_id:onJSON['full']).first
    return if targetAnnotation.nil?
    return(targetAnnotation) if (targetAnnotation.on.to_s.include?("oa:SvgSelector"))
    getTargetedAnno targetAnnotation
  end
end
