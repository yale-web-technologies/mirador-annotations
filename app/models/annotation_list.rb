class AnnotationList < ActiveRecord::Base
  has_many :list_annotations_maps, foreign_key: :list_id, primary_key: :list_id
  has_many :webacls, foreign_key: "resource_id"

  has_many :layer_lists_maps, foreign_key: :list_id, primary_key: :list_id
  has_many :annotations, through: :list_annotations_maps

  has_many :annotation_layers, through: :layer_lists_maps
  belongs_to :canvas

  def self.create_from_iiif(json_obj)
    params = json_obj.merge(list_id: json_obj['@id'],
      list_type: json_obj['@type'])
    params.delete('@id')
    params.delete('@type')
    params.delete('@context')
    self.create(params)
  end

  def to_iiif
    iiif = Hash.new
    iiif['@id'] = list_id
    iiif['@type'] = list_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.blank?
    iiif['within'] = LayerListsMap.getLayersForList list_id
    # temp [jrl] data needs to be fixed
    #iiif['resources'] = ListAnnotationsMap.getAnnotationsForList list_id
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
