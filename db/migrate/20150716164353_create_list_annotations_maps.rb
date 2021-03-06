class CreateListAnnotationsMaps < ActiveRecord::Migration
  def change
    create_table :list_annotations_maps do |t|
      t.string :list_id
      t.integer :sequence
      t.string :annotation_id

      t.timestamps null: false
    end
    add_index :list_annotations_maps, :list_id
    add_index :list_annotations_maps, :annotation_id
  end
end
