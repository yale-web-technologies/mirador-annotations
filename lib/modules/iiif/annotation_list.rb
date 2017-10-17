module IIIF
  class AnnotationList
    def self.create(id:, options:)
      {
        '@context' => "http://iiif.io/api/presentation/2/context.json",
        '@id' => id,
        '@type' => 'sc:AnnotationList',
        'label' => 'An annotation list',
        'resources' => []
      }.merge(options)
    end
  end
end
