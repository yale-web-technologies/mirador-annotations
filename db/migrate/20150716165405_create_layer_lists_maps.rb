class CreateLayerListsMaps < ActiveRecord::Migration[4.2]
  def change
    create_table :layer_lists_maps do |t|
      t.string :layer_id
      t.integer :sequence
      t.string :list_id

      t.timestamps null: false
    end
    add_index :layer_lists_maps, :layer_id
    add_index :layer_lists_maps, :list_id
  end
end
