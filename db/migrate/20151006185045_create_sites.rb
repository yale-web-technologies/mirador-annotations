class CreateSites < ActiveRecord::Migration[4.2]
  def change
    create_table :sites do |t|
      t.string :site_id
      t.string :site_title
      t.string :site_description

      t.timestamps null: false
    end
  end
end
