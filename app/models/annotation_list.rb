class AnnotationList < ActiveRecord::Base

  attr_accessible  :list_id,
                   :@type,
                   :resources,
                   :within
end
