class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :collection_id
      t.string :label
      t.text :description

      t.timestamps null: false
    end
  end
end
