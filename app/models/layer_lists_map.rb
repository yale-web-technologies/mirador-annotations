class LayerListsMap < ActiveRecord::Base
  belongs_to :annotation_layer


  attr_accessible  :layer_id,
                   :sequence,
                   :list_id
end
