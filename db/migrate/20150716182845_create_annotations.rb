class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.string :annotation_id
      t.string :annotation_type
      t.string :motivation
      t.string :label
      t.string :description
      t.string :on
      t.string :canvas
      t.string :manifest
      t.string :resource
      t.boolean :active
      t.integer :version
      t.string :annotated_by

      t.timestamps null: false
    end
    add_index :annotations, :annotation_id
  end
end
