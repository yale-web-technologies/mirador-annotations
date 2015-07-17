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
    @listIds.each do |listId|
      @list = AnnotationList.where(list_id: listId.list_id).first
      # as a hash as per api 6.3
      #@idJson = Hash.new
      #@idJson['@id'] = @list.list_id
      # as a url string as per api 8.2
      @idJson= @list.list_id
      p 'idJson = ' + @idJson.to_s
      @otherContentArr.push(@idJson)
    end

    iiif = Hash.new
    iiif['@id'] = layer_id
    iiif['@type'] = layer_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.empty?
    iiif['motivation'] = motivation if !motivation.empty?
    iiif['license'] = license if !license.empty?
    #iiif['otherContent'] = othercontent.split(",")
    iiif['otherContent'] = @otherContentArr
    iiif
  end

end
