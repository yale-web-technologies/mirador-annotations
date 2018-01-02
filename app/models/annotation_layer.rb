class AnnotationLayer < ActiveRecord::Base
  validates :layer_id, uniqueness: true

  has_and_belongs_to_many :groups

  has_many :webacls, foreign_key: "resource_id"

  has_many :layer_lists_maps, foreign_key: :layer_id, primary_key: :layer_id
  has_many :annotation_lists, through: :layer_lists_maps

  def self.create_from_iiif(json_obj)
    # params = json_obj.merge(layer_id: json_obj['@id'],
    #   layer_type: json_obj['@type'])
    # params.delete('@id')
    # params.delete('@type')
    # params.delete('@context')
    # self.create(params)

    params = {
      layer_id: json_obj['@id'],
      layer_type: json_obj['@type'] || 'sc:Layer',
      label: json_obj['label'] || '',
      description: json_obj['description'] || '',
      version: json_obj['version'] || 1
    }
    self.create(params)
  end

  def to_iiif
    iiif = Hash.new
    iiif['@id'] = layer_id
    iiif['@type'] = layer_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.blank?
    iiif['motivation'] = motivation if !motivation.blank?
    iiif['license'] = license if !license.blank?
    iiif['description'] = description if !description.blank?
    iiif['otherContent'] = LayerListsMap.getListsForLayer layer_id
    iiif
  end

  def to_version_content
    version_content = Hash.new
    version_content['@id'] = layer_id
    version_content['@type'] = layer_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['label'] = label if !label.blank?
    version_content['motivation'] = motivation if !motivation.blank?
    version_content['license'] = license if !license.blank?
    version_content['description'] = description if !description.blank?
    version_content['otherContent'] = LayerListsMap.getListsForLayer layer_id
    version_content
  end

end

