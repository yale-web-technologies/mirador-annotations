class AnnotationList < ActiveRecord::Base

  attr_accessible  :list_id,
                   :list_type,
                   :resources,
                   :within
end
