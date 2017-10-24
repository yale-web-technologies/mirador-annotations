class AnnotationTagMap < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :annotation_tag
end
