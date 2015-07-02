class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.string :annotation_id
      t.text :resource
      t.boolean :active
      t.integer :version
      t.timestamps null: false
    end
  end
end
