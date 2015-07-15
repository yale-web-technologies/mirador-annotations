class ListAnnotationsMap < ActiveRecord::Base
  attr_accessible  :list_id,
                   :sequence,
                   :annotation_id

  def self.setMap within, anno_id
    if !within.nil?
      within.each do |list_id|
        newHighSeq = getNextSeqForList(list_id)
        create!(:list_id => list_id, :sequence => newHighSeq, :annotation_id => anno_id)
      end
    end
  end

  def self.getNextSeqForList list_id
    highestSeq = self.where(list_id: list_id).order(:sequence).last
    if !highestSeq.nil?
      nextSeq = highestSeq.sequence + 1
    else
      nextSeq = 1
    end
    nextSeq
  end

  def self.getListsForAnnotation anno_id
    within = Array.new
    @annotationLists = self.where(annotation_id: anno_id)
    @annotationLists.each do |annoList|
      within.push(annoList.list_id)
    end
    within
  end

end
