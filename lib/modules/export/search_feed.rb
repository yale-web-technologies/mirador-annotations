module Export
  # Generate feeds for Drupal (to be ultimately consumed for Solr search)
  class SearchFeed
    @@context = "http://iiif.io/api/presentation/2/context.json"
    @@canvas_map = {
      'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01' => 'Panel 1',
      'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11' => 'Panel 2'
    }

    def feed_annotations_no_resource
      rows = []
      annotations = Annotation.where(active: true)

      # Header
      rows << ['annotation_id', 'annotation_type', 'context', 'on', 'canvas',
        'motivation', 'layers', 'bounding_box', 'panel', 'chapter', 'scene',
        'display_name']

      annotations.each do |annotation|
        begin
          rows << create_row_no_resource(annotation)
        rescue Exception => e
          puts "ERROR failed to export (no_resource) #{annotation.annotation_id} - #{e}"
        end
      end
      rows
    end

    def feed_annotations_resource_only
      rows = []
      annotations = Annotation.where(active: true)

      # Header
      rows << ["annotation_id", "resource_id", "type", "format", "chars"]

      annotations.each do |annotation|
        begin
          rows << create_row_resource_only(annotation)
        rescue Exception => e
         puts "ERROR failed to export (resource_only) #{annotation.annotation_id} - #{e}"
        end
      end
      rows
    end

private

    def create_row_no_resource(annotation)
      anno = IIIF::Anno.new(annotation)
      puts "id: #{anno.id}"

      target_id = nil  # eventual target canvas
      canvas_id = nil  # immediate target canvas

      xywh = annotation.service_block.gsub(/\r\n?/, '') if annotation.service_block?
      puts "xywh: #{xywh}"

      layers = annotation.getLayersForAnnotation(annotation.annotation_id).join(', ')
      puts "layers: #{layers}"

      motivation = anno.motivation.join(', ')
      puts "motivation: #{motivation}"

      target = anno.targets.first

      if IIIF::Target.is_annotation(target)
        target_annos = Annotation.find_target_annotations_on_canvas(annotation)
        if target_annos.empty?
          puts "ERROR no targets on canvas found for annotation #{anno.id}"
        else
          target_annos.each do |target|
            puts "target: #{target.annotation_id}"
          end
        end
        target_id = target['full']
        target_anno = target_annos.first
        canvas_id = IIIF::Anno.get_targets(target_anno).first['full']

      else  # target is a canvas fragment
        target_id = ''
        canvas_id = target['full']
      end

      chapter, scene, sequence = [nil, nil, nil]

      anno.tags.each do |tag_object|
        tag_string = tag_object['chars']
        m = tag_string.match(/^chapter(\d+)$/)
        chapter = "Chapter #{m[1]}" if m
        m = tag_string.match(/^scene(\d+)$/)
        scene = "Scene #{m[1]}" if m
        m = tag_string.match(/^p(\d+)$/)
        sequence = "Sequence #{m[1]}" if m
      end
      puts "tags: #{anno.tags.inspect}"

      panel = @@canvas_map[canvas_id]
      puts "panel: [#{panel}], chapter: [#{chapter}], scene: [#{scene}], sequence: [#{sequence}]"

      label = "#{panel} #{chapter}"
      label += " #{scene}" if scene
      label += " #{sequence}" if sequence

      [anno.id, anno.type, @@context, target_id, canvas_id, anno.motivation, layers,
        xywh, panel, chapter, scene, label]
    end

    def create_row_resource_only(annotation)
      anno = IIIF::Anno.new(annotation)
      resource_id = "#{anno.id}_#{SecureRandom.uuid}"

      resource_items = anno.resource.select { |r| r['@type'] == 'dctypes:Text' }
      raise "Annotation #{anno.id} has no text resource" if resource_items.empty?
      resource_item = resource_items.first
      chars = ActionView::Base.full_sanitizer.sanitize(resource_item['chars'])

      [anno.id, resource_id, resource_item['@type'], resource_item['format'], chars]
    end
  end
end