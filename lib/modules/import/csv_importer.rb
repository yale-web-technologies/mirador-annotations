module Import
  require 'csv'

  class CsvImporter
    @@canvas_map = {
      '1' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/panel_01',
      '2' => 'http://manifests.ydc2.yale.edu/LOTB/canvas/bv11'
    }

    def initialize(hostUrl)
      @hostUrl = hostUrl
    end

    def import(csv)
      CSV.parse(csv, headers: true) do |row|
        import_row(row)
      end
    end

  private
    def import_row(row)
      panel = panel.nil? ? '' : row[0].strip
      chapter = chapter.nil? '' : row[1].strip
      scene = scene.nil? '' : row[2].strip
      scene = '0' if scene.empty?
      canvas = @@canvas_map[panel]

      annotation_id = build_annotation_id(panel, chapter, scene, sequence)
    end

    def build_annotatin_id(panel, chapter, scene, sequence)
      "@hostUrl/annotations/Panel_#{panel}_Chapter_#{chapter}_Scene_#{scene}_#{sequence}"
    end
  end
end
