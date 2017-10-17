module IIIF
  class Layer
    def self.create(id:, options: {})
      {
        '@context' => "http://iiif.io/api/presentation/2/context.json",
        '@id' => id,
        '@type' => 'sc:Layer',
        'label' => 'A layer',
        'otherContent': []
      }.merge(options)
    end
  end
end
