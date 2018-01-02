class CreateLayerMappings < ActiveRecord::Migration[4.2]
  def change
    create_table :layer_mappings do |t|
      t.string :layer_id
      t.string :new_layer_id
      t.string :label

      t.timestamps null: false
    end
  end
end
