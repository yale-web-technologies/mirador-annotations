class AnnotationLayer < ActiveRecord::Base
  validates :layer_id, uniqueness: true
  has_many :layer_lists_maps
  attr_accessible :layer_id,
                  :layer_type,
                  :label,
                  :motivation,
                  :description,
                  :license,
                  :othercontent,
                  :version

  def to_iiif
    # get the layer's list records via the sequencing map table to build otherContent
    @otherContentArr = Array.new
    @listIds = LayerListsMap.where(layer_id:layer_id).order(:sequence)
    @listIds.each do |listId|
      @list = AnnotationList.where(list_id: listId.list_id).first
      @idJson= @list.list_id
      @otherContentArr.push(@idJson)
    end

    iiif = Hash.new
    iiif['@id'] = layer_id
    iiif['@type'] = layer_type
    iiif['@context'] = "http://iiif.io/api/presentation/2/context.json"
    iiif['label'] = label if !label.blank?
    iiif['motivation'] = motivation if !motivation.blank?
    iiif['license'] = license if !license.blank?
    #iiif['otherContent'] = othercontent.split(",")
    iiif['otherContent'] = @otherContentArr
    iiif
  end

  def to_version_content
    # get the layer's list records via the sequencing map table to build otherContent
    @otherContentArr = Array.new
    @listIds = LayerListsMap.where(layer_id:layer_id).order(:sequence)
    @listIds.each do |listId|
      @list = AnnotationList.where(list_id: listId.list_id).first
      @idJson= @list.list_id
      @otherContentArr.push(@idJson)
    end

    version_content = Hash.new
    version_content['@id'] = layer_id
    version_content['@type'] = layer_type
    version_content['@context'] = "http://iiif.io/api/presentation/2/context.json"
    version_content['label'] = label if !label.blank?
    version_content['motivation'] = motivation if !motivation.blank?
    version_content['license'] = license if !license.blank?
    version_content['description'] = description if !description.blank?
    version_content['otherContent'] = @otherContentArr
    version_content
  end

end
