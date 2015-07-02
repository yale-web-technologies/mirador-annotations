class CreateLayerListsMaps < ActiveRecord::Migration
  def change
    create_table :layer_lists_maps do |t|
      t.string :layer_id
      t.integer :sequence
      t.string :list_id
      t.timestamps null: false
    end
  end
end
