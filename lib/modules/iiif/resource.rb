module IIIF
  class Resource
    def self.create(id:, options: {})
      [{
        '@type' => 'dctypes:Text',
        'format' => 'text/html',
      }.merge(options)]
    end
  end
end