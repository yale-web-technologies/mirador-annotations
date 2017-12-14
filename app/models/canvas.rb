class Canvas < ActiveRecord::Base
  has_many :annotation_lists

  def annotations
    annos = []
    annotation_lists.each do |list|
      annos.concat(list.annotations)
    end
    annos.uniq
  end
end
