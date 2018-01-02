class CreateAnnotationLists < ActiveRecord::Migration[4.2]
  def change
    create_table :annotation_lists do |t|
      t.string :list_id
      t.string :list_type
      t.string :label
      t.string :description

      t.timestamps null: false
    end
    add_index :annotation_lists, :list_id
  end
end
