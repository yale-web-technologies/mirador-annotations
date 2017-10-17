module IIIF
  class Annotation
    def self.create(id:, resource:, target:, options: {})
      annotation = {
        '@context' => "http://iiif.io/api/presentation/2/context.json",
        '@type' => 'oa:Annotation',
        'motivation' => ['oa:commenting'],
        'resource' => resource,
        'on' => target
      }.merge(options)
      annotation['@id'] = id unless id.nil?
      annotation
    end
  end
end
