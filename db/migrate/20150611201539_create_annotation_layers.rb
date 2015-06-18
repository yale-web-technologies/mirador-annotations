class CreateAnnotationLayers < ActiveRecord::Migration
  def change
    create_table :annotation_layers do |t|
      t.string :@id
      t.string :@type
      t.string :@context
      t.string :label
      t.string :motivation
      t.string :description
      t.string :license
      t.string :otherContent

      t.timestamps null: false
    end
  end
end
