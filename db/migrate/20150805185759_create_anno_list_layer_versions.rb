class CreateAnnoListLayerVersions < ActiveRecord::Migration
  def change
    create_table :anno_list_layer_versions do |t|
      t.string :all_id
      t.string :all_type
      t.integer :all_version
      t.string :all_content

      t.timestamps null: false
    end
  end
end
