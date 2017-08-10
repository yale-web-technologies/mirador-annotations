module IIIF
  class Collection
    def self.parse_collection(collection_json)
      Collection.new(JSON.parse(collection_json))
    end

    ## collection_data: a hash from json
    def initialize(collection_data)
      @collection_data = collection_data
    end

    def label
      @collection_data['label']
    end

    def manifests
      @collection_data['manifests']
    end
  end
end