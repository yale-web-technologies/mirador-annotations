class Annotation < ActiveRecord::Base
  attr_accessible :annotation_id,
                  :resource,
                  :active,
                  :version

  def to_iiif
    iiif = JSON.parse(resource)
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    #iiif.delete(on)
    #iiif.on = resource.on
    iiif
  end
end
