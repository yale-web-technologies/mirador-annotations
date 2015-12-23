class Annotation < ActiveRecord::Base
  attr_accessible :annotation_id,
                  :annotation_type,
                  :motivation,
                  :description,
                  :on,
                  :canvas,
                  :resource,
                  :version,
                  :annotated_by,
                  :active,
                  :version
  has_many :webacls, foreign_key: "resource_id"

  def to_iiif
    iiif = Hash.new
    iiif['@id'] = annotation_id
    iiif['@type'] = annotation_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['motivation'] = motivation
    iiif['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    iiif['resource'] = JSON.parse(resource)
    #iiif['annnotatedBy'] = JSON.parse(annotated_by) if !iiif['annnotatedBy'].empty?
    iiif['on'] = on
    iiif.to_json
  end

  def to_version_content
    version_content = Hash.new
    version_content['@id'] = annotation_id
    version_content['@type'] = annotation_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['motivation'] = motivation
    version_content['within'] = ListAnnotationsMap.getListsForAnnotation annotation_id
    version_content['resource'] = resource.to_json
    version_content['annnotatedBy'] = annotated_by.to_json
    version_content['on'] = on
    version_content.to_json
  end

end
