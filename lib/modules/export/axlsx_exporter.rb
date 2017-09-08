module Export
  require 'open-uri'

  class AxlsxExporter
    ## collection: a IIIF::Collection
    def initialize(collection, layers)
      manifest_urls = collection.manifests.map { |manifest| manifest['@id'] }
      @manifests = download_manifests(manifest_urls)
      @layers = layers
    end

    def export(wb)
      @manifests.each do |manifest|
        wb.add_worksheet(name: 'Annotations') do |sheet|
          sheet.name = manifest.label
          sheet.add_row(header_row)
          export_manifest(manifest).each do |row|
            sheet.add_row(row)
          end
          sheet.column_widths(*column_widths)
        end
      end
    end

    def column_widths
      [nil, nil, nil, 40, 80, 40, 80, 40, 80]
    end

  private
    def download_manifests(manifest_urls)
      manifests = []
      manifest_urls.each do |url|
        Rails.logger.debug("Getting manifest from #{url}")
        manifest_json = open(url).read
        manifest = IIIF::Manifest.parse_manifest(manifest_json)
        manifests << manifest
      end
      manifests
    end

    def header_row
      return ['Text',
        'Text Division',
        'Layer',
        'Annotation (ID)',
        'Annotation (Body)',
        'Targetd By (ID)',
        'Targeted By (Body)',
        'Target (ID)',
        'Target (Body)'
      ]
    end

    def export_manifest(manifest)
      rows = []
      manifest.canvases.each do |canvas|
        rows.concat(export_canvas(manifest, canvas))
      end
      rows
    end

    def export_canvas(manifest, canvas)
      rows = []
      annotations = Annotation.where(canvas: canvas['@id'], active: true)
      annotations = get_targeting_annoations(annotations)
      annos_struct = group_by_layer(annotations)
      @layers.each do |layer|
        pairs = annos_struct[layer.layer_id]
        pairs && pairs.each do |pair|
          puts "PAIR: #{pair} #{pair[0]} #{pair[1]}"
          annotation = pair[0]
          rows << generate_row(manifest, canvas, layer, annotation, true)
        end
      end
      #rows = check_invalid_layers(rows, annos_struct, manifest, canvas)
      rows
    end

    def check_invalid_layers(rows, annos_struct, manifest, canvas)
      annos_struct.each do |layer_id, pairs|
        unless @layers.include? layer_id
          pairs = annos_struct[layer_id]
          pairs && pairs.each do |pair|
            annotation = pair[0]
            rows << generate_row(manifest, canvas, layer_id, annotation, false)
          end
          anno_ids = pairs.map { |p| p[0].annotation_id }
          Rails.logger.error("ERROR invalid layer #{layer_id} for #{anno_ids}")
        end
      end
      rows
    end

    def get_targeting_annoations(annotations)
      new_annos = []
      annotations.each do |anno|
        new_annos << anno
        new_annos += IIIF::Anno.new(anno).targeting_annotations
      end
      new_annos
    end

    def generate_row(manifest, canvas, layer, annotation, valid)
      anno = IIIF::Anno.new(annotation)

      if valid
        layer_label = layer.label
      else
        layer_label = "INVALID layer #{layer}"
      end

      body_text = anno.body_text || ''
      targeting_annos = anno.targeting_annotations.map { |anno| IIIF::Anno.new(anno) }
      targeting_annos_body_texts = targeting_annos.map { |anno| strip_html_tags(anno.body_text) }
      targeting_annos_ids = targeting_annos.map { |anno| anno.id }
      target_annos = anno.target_annotations.map { |anno| IIIF::Anno.new(anno) }
      target_annos_body_texts = target_annos.map { |anno| strip_html_tags(anno.body_text) }
      target_annos_ids = target_annos.map { |anno| anno.id }

      [ manifest.label,
        canvas['label'],
        layer_label,
        anno.id,
        strip_ms_tags(body_text),
        targeting_annos_ids.join('|'),
        targeting_annos_body_texts.join('|'),
        target_annos_ids.join('|'),
        target_annos_body_texts.join('|')
      ]
    end

    def strip_ms_tags(s)
      if s.match(/<!--.*?-->/m)  # if deemed copied from MS word
        return strip_html_tags(s)
      else
        return s
      end
    end

    def strip_html_tags(s)
      ActionController::Base.helpers.strip_tags(s).strip
    end

    def group_by_layer(annotations)
      annos_struct = {}
      annotations.each do |annotation|
        layer, order_weight = get_layer_for_annotation(annotation)
        layer_id = layer && layer.layer_id
        annos_struct[layer_id] = [] if annos_struct[layer_id].nil?
        annos_struct[layer_id] << [annotation, order_weight.to_i]
      end
      sort_annotations(annos_struct)
    end

    def sort_annotations(annos_struct)
      new_struct = {}
      annos_struct.each do |layer_id, anno_pairs|
        new_struct[layer_id] = anno_pairs.sort_by { |pair| pair[1] }  # sort by weight value
      end
      new_struct
    end

    def get_layer_for_annotation(annotation)
      puts "anno: #{annotation.annotation_id}"
      list_annotations = ListAnnotationsMap.where(annotation_id: annotation.annotation_id)

      list_annotation = list_annotations[0]
      puts "list_annotation: #{list_annotation}"
      list_id = list_annotation.list_id
      puts "list_id: #{list_id}"
      order_weight = list_annotation.sequence
      puts "weight: #{order_weight}"
      layer_lists = LayerListsMap.where(list_id: list_id)
      layer_list = layer_lists[0]
      puts "layer_list: #{layer_list}"
      layer_id = layer_list.layer_id
      puts "layer_id: #{layer_id}"
      layers = AnnotationLayer.where(layer_id: layer_id)
      layer = layers[0]
      puts "layer: #{layer}"
      [layer, order_weight]
    end
  end
end
