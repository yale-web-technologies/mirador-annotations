class AddListsToLayers < ActiveRecord::Migration[4.2]
  def change
    add_reference :annotation_lists, :annotation_layer, index: true, foreign_key: true
  end
end
