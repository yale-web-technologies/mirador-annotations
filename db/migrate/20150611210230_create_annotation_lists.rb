class CreateAnnotationLists < ActiveRecord::Migration
  def change
    create_table :annotation_lists do |t|
      t.string :@id
      t.string :@type
      t.string :resources
      t.string :layers

      t.timestamps null: false
    end
  end
end
