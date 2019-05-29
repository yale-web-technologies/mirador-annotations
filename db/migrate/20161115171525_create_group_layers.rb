class CreateGroupLayers < ActiveRecord::Migration[4.2]
  def change
    create_table :annotation_layers_groups, id: false do |t|
      t.belongs_to :group, index: :true
      t.belongs_to :annotation_layer, index: :true
    end
  end
end
