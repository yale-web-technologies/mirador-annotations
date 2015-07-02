class CreateAnnotationLists < ActiveRecord::Migration
  def change
    create_table :annotation_lists do |t|
      t.string :list_id
      t.string :list_type
      t.string :resources
      t.string :within

      t.timestamps null: false
    end
  end
end
