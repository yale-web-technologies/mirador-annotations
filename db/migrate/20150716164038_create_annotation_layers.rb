class CreateAnnotationLayers < ActiveRecord::Migration[4.2]
  def change
    create_table :annotation_layers do |t|
      t.string :layer_id
      t.string :layer_type
      t.string :motivation
      t.string :label
      t.string :description
      t.string :license

      t.timestamps null: false
    end
    add_index :annotation_layers, :layer_id
  end
end
