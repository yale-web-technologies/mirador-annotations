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
      svg_paths = get_svg_paths(target['selector']['value'])
      unless svg_paths.empty?
        firstComma = svg_paths[0].index(',')
        xywh = Annotation.get_xywh_from_svg(svg_paths, max_width, max_height)
      end
    else
      puts "ERROR invalid target #{target.inspect} for annotation #{annotation.annotation_id}"
    end

    # update annotation here
    annotation.update_attributes(:service_block => xywh)
    puts "C: #{annotation.annotation_id} [#{annotation.service_block}]"
  end

  def get_svg_paths(svg)
    svg_paths = []

    svg.scan(/\Wd=["']([^"']*)['"]/) do |match|
      svg_paths << match[0]
    end

    svg_paths
  end
end
