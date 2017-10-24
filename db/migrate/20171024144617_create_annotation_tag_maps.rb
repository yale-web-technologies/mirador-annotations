class CreateAnnotationTagMaps < ActiveRecord::Migration
  def change
    create_table :annotation_tag_maps do |t|
      t.belongs_to :annotation
      t.belongs_to :annotation_tag
      t.timestamps null: false
    end
  end
end
