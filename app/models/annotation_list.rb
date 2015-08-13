class AnnotationList < ActiveRecord::Base
  attr_accessible  :list_id,
                   :list_type,
                   :label,
                   :description,
                   :version
  def to_iiif
    iiif = Hash.new
    iiif['@id'] = list_id
    iiif['@type'] = list_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.blank?
    iiif['within'] = LayerListsMap.getLayersForList list_id
    iiif['resources'] = ListAnnotationsMap.getAnnotationsForList list_id
    iiif
  end

  def to_version_content
    version_content = Hash.new
    version_content['@id'] = list_id
    version_content['@type'] = list_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['label'] = label if !label.blank?
    version_content['within'] = LayerListsMap.getLayersForList list_id
    version_content['resources'] = ListAnnotationsMap.getAnnotationListForList list_id
    version_content
  end
end
