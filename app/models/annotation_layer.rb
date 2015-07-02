class AnnotationLayer < ActiveRecord::Base
  validates :layer_id, uniqueness: true
  has_many :layer_lists_maps
  attr_accessible :layer_id,
                  :layer_type,
                  :label,
                  :motivation,
                  :description,
                  :license

  def to_iiif
    iiif = attributes.clone
    iiif['@id'] = layer_id
    iiif['@type'] = layer_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"

    iiif.delete('id')
    iiif.delete('layer_id')
    iiif.delete('layer_type')
    iiif.delete('otherContent')
    iiif.delete('description') if description.nil? or description.empty?
    iiif.delete('license') if license.nil? or license.empty?
    iiif.delete('motivation') if motivation.nil? or motivation.empty?
    iiif.delete('created_at')
    iiif.delete('updated_at')

    iiif['otherContent'] = otherContent.split(",")
    p  iiif['otherContent'].to_s
    iiif
  end

end
