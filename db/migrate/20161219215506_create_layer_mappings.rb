class CreateLayerMappings < ActiveRecord::Migration
  def change
    create_table :layer_mappings do |t|
      t.string :layer_id
      t.string :new_layer_id
      t.string :label

      t.timestamps null: false
    end
  end
end
