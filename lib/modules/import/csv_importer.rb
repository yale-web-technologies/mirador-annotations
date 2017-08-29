module Import
  require 'csv'
  require 'creation-helper'

  class CsvImporter
    @@canvas_map = {
      '1' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01',
      '2' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11'
    }

    def initialize(hostUrl)
      @hostUrl = hostUrl
      @helper = IIIF::CreationHelper.new
    end

    def import(csv)
      last_scene = '-1'
      sequence = 0

      CSV.parse(csv, headers: true) do |row|
        last_scene, sequence = import_row(row, last_scene, sequence)
      end
    end

  private
    def import_row(row, last_scene, sequence)
      parsed = parse_row(row)

      if (parsed[:scene] != last_scene)
        last_scene = parsed[:scene]
        sequence = 0
      end
      sequence += 1

      [
        IIIF::LAYER_KEY_ENGLISH,
        IIIF::LAYER_KEY_TIBETAN,
        IIIF::LAYER_KEY_ENGLISH_MANUAL,
        IIIF::LAYER_KEY_TIBETAN_MANUAL,
        IIIF::LAYER_KEY_ENGLISH_INSCRIPTION,
        IIIF::LAYER_KEY_TIBETAN_INSCRIPTION,
        IIIF::LAYER_KEY_CANONICAL_SOURCE,
        IIIF::LAYER_KEY_CANONICAL_SOURCE_2RY_3RY,
        IIIF::LAYER_KEY_SCENE_WORKING_NOTES
      ].each do |layer_key|
        create_annotation(layer_key, parsed, sequence) if parsed[layer_key]
      end

      [parsed[:scene], sequence]
    end

    def create_annotation(layer_key, r, sequence)
      annotation = @helper.create_annotation(layer_key: layer_key,
        panel: r[:panel], chapter: r[:chapter], scene: r[:scene], sequence: sequence,
        body_text: r[layer_key])
      print_anno(annotation)
      result = annotation.save!(options={validate: false})

      list_id = @helper.create_list_id(layer_key: layer_key, panel: r[:panel])
      puts "List: #{list_id}"
      puts "Anno: #{annotation['annotation_id']}"
      puts
      ListAnnotationsMap.setMap [list_id], annotation['annotation_id']
    end

    def print_anno(annotation)
      puts "ID: #{annotation.annotation_id}"
      puts "Label: #{annotation.label}"
      puts "Resource: #{annotation.resource}"
      puts "On: #{annotation.on}"
    end

    def parse_row(row)
      panel = prune_text(row[0])
      scene = prune_text(row[2])
      scene = '0' if scene.nil?

      {
        :panel => panel,
        :chapter => prune_text(row[1]),
        :scene => scene,
        IIIF::LAYER_KEY_TIBETAN => prune_text(row[3]),
        IIIF::LAYER_KEY_TIBETAN_INSCRIPTION => prune_text(row[5]),
        IIIF::LAYER_KEY_TIBETAN_MANUAL => prune_text(row[7]),
        IIIF::LAYER_KEY_ENGLISH => prune_text(row[4]),
        IIIF::LAYER_KEY_ENGLISH_INSCRIPTION => prune_text(row[6]),
        IIIF::LAYER_KEY_ENGLISH_MANUAL => prune_text(row[8]),
        IIIF::LAYER_KEY_CANONICAL_SOURCE => prune_text(row[9]),
        IIIF::LAYER_KEY_CANONICAL_SOURCE_2RY_3RY => prune_text(row[10]),
        IIIF::LAYER_KEY_SCENE_WORKING_NOTES => prune_text(row[11]),
        :canvas => @@canvas_map[panel]
      }
    end

    def prune_text(s)
      return nil if s.nil?
      s = s.strip
      return nil if s.empty?
      s
    end
  end
end
