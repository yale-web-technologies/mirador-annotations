class AnnotationLayer < ActiveRecord::Base
  validates :layer_id, uniqueness: true
  has_many :layer_lists_maps
  attr_accessible :layer_id,
                  :layer_type,
                  :label,
                  :motivation,
                  :description,
                  :license,
                  :othercontent

  def to_iiif
    # get the layer's list records via the sequencing map table to build otherContent
    @otherContentArr = Array.new
    @listIds = LayerListsMap.where(layer_id:layer_id).order(:sequence)
p @listIds.count.to_s
      @listIds.each do |listId|
        @list = AnnotationList.where(list_id: listId.list_id).first
        @idJson = Hash.new
        @idJson['@id'] = @list.list_id
        p 'idJson = ' + @idJson.to_s
        @otherContentArr.push(@idJson)
      end

    iiif = attributes.clone
    iiif['@id'] = layer_id
    iiif['@type'] = layer_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"

    iiif.delete('id')
    iiif.delete('layer_id')
    iiif.delete('layer_type')
    iiif.delete('othercontent')
    iiif.delete('description') if description.nil? or description.empty?
    iiif.delete('license') if license.nil? or license.empty?
    iiif.delete('motivation') if motivation.nil? or motivation.empty?
    iiif.delete('created_at')
    iiif.delete('updated_at')

    #iiif['otherContent'] = othercontent.split(",")
    iiif['otherContent'] = @otherContentArr
    iiif
  end


end
