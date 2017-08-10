module IIIF
  class Manifest
    def self.parse_manifest(manifest_json)
      Manifest.new(JSON.parse(manifest_json))
    end

    ## collection_data: a hash from json
    def initialize(manifest_data)
      @manifest_data = manifest_data
    end

    def label
      @manifest_data['label']
    end

    def canvases
      @manifest_data['sequences'][0]['canvases']
    end
  end
end