class Annotation < ActiveRecord::Base
  attr_accessible :annotation_id,
                  :annotation_type,
                  :resource,
                  :active,
                  :version,
                  :description,
                  :label,
                  :annotated_by,
                  :motivation,
                  :on,
                  :canvas,
                  :resource,
                  :active,
                  :version

  def to_iiif
    iiif = Hash.new
    iiif['@id'] = annotation_id
    iiif['@type'] = annotation_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['motivation'] = motivation
    iiif['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id if !iiif['within'].blank?
    iiif['resource'] = JSON.parse(resource)
    iiif['annnotatedBy'] = JSON.parse(annotated_by) if !iiif['annnotatedBy'].blank?
    iiif['on'] = on
    iiif
  end

end
