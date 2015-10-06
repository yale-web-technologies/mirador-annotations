class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :site_id
      t.string :site_title
      t.string :site_description

      t.timestamps null: false
    end
  end
end
