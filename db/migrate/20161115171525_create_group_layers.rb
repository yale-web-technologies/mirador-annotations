class CreateGroupLayers < ActiveRecord::Migration
  def change
    create_table :annotation_layers_groups, id: false do |t|
      t.belongs_to :group, index: :true
      t.belongs_to :annotation_layer, index: :true
    end
  end
end