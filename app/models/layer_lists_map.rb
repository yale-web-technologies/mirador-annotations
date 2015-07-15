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

  # ready to test; next do above 2.
  def self.getLayersForList list_id
    within = Array.new
    @annotationLayers = self.where(list_id: list_id)
    @annotationLayers.each do |annoLayer|
      within.push(annoLayer.layer_id)
    end
    within
  end

end
