module Export
  require 'csv'
  require 'open-uri'

  class CsvExporter
    def initialize(collection)
      @manifest_urls = collection['manifests'].map{ |manifest| manifest['@id'] }
    end

    def export
      text = header
      @manifest_urls.each do |url|
        manifest_json = open(url).read
        manifest = JSON.parse(manifest_json)
        text << export_manifest(manifest)
      end
      text.html_safe
    end

    def header
      return ['Text',
        'Text Division',
        'Annotation ID',
        'Annotation'
      ].to_csv
    end

    def export_manifest(manifest)
      text = ''
      canvases = manifest['sequences'][0]['canvases']
      canvases.each do |canvas|
        text << export_canvas(manifest, canvas)
      end
      text
    end

    def export_canvas(manifest, canvas)
      text = ''
      annotations = Annotation.where(canvas: canvas['@id'])
      annotations.each do |anno|
        puts anno['@id']
        text << [ manifest['label'],
          canvas['label'],
          anno['@id'],
          anno['resource'][0]['chars']
        ].to_csv
      end
      text
    end
  end
end
