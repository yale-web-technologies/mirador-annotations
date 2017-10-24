class AnnotationTag < ActiveRecord::Base
  has_many :annotation_tag_maps
  has_many :annotations, through: :annotation_tag_maps
end
