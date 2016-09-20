class LayerListsMap < ActiveRecord::Base
  belongs_to :annotation_layer

  attr_accessible  :layer_id,
                   :sequence,
                   :list_id
  def self.setMap within, list_id
    if !within.nil?
      within.each do |layer_id|
        newHighSeq = getNextSeqForLayer(layer_id)
        create!(:layer_id => layer_id, :sequence => newHighSeq, :list_id => list_id)
      end
    end
  end

  def self.getNextSeqForLayer layer_id
    highestSeq = self.where(layer_id: layer_id).order(:sequence).last
    if !highestSeq.nil?
      nextSeq = highestSeq.sequence + 1
    else
      nextSeq = 1
    end
    nextSeq
  end

  def self.getLayersForList list_id
    within = Array.new
    @annotationLayers = self.where(list_id: list_id)
    @annotationLayers.each do |annoLayer|
      within.push(annoLayer.layer_id)
    end
    within
  end

  def self.getLayerLabelsForList list_id
    within = Array.new
    @annotationLayers = self.where(list_id: list_id)
    @annotationLayers.each do |thisLayer|
      layer = AnnotationLayer.where(layer_id: thisLayer.layer_id).first
      within.push(layer.label)
    end
    within
  end

  def self.getListsForLayer layer_id
    otherContent = Array.new
    @annotationLists = self.where(layer_id: layer_id).order(:sequence)
    @annotationLists.each do |annoList|
        otherContent.push(annoList.list_id)
    end
    otherContent
  end

  def self.deleteListFromLayer list_id
    @annotationLayers = self.where(list_id: list_id)
    @annotationLayers.each do |annoLayer|
      annoLayer.destroy
    end
  end

end
