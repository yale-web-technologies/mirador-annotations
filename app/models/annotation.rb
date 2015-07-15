class Annotation < ActiveRecord::Base
  attr_accessible :annotation_id,
                  :resource,
                  :active,
                  :version,
                  :within

  def to_iiif
    iiif = Hash.new
    iiif['@id'] = annotation_id
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    iiif.merge(JSON.parse(resource))
  end

  def validate_annotation annotation
    if !annotation['type']=='sc:annotation'
      p 'now what? bad type: ' + annotation['type']
    end
  end

end
