class AnnotationLayer < ActiveRecord::Base
  validates :@id, uniqueness: true
  has_many :layer_lists_maps

  attr_accessible  :list_id,
                  :list_type,
                  :label,
                  :motivation,
                  :description,
                  :license
  def to_iiif
    iiif = attributes.clone
    iiif.delete('_id')
    iiif.delete('description') if description.nil? or description.empty?
    iiif.delete('attribution') if attribution.nil? or attribution.empty?
    iiif.delete('license') if license.nil? or license.empty?
    iiif.delete('motivation') if motivation.nil? or motivation.empty?
    iiif['@context'] = ["http://iiif.io/api/presentation/2/context.json"]
    iiif
  end

  def to_iiif
    iiif = attributes.clone
    iiif.delete('_id')
    iiif.delete('description') if description.nil? or description.empty?

    iiif.delete('license') if license.nil? or license.empty?
    iiif.delete('motivation') if motivation.nil? or motivation.empty?
    iiif['@context'] = ["http://iiif.io/api/presentation/1/context.json"]
    iiif
  end

end
