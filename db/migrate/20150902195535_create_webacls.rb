class CreateWebacls < ActiveRecord::Migration
  def change
    create_table :webacls do |t|
      t.string :resource_id
      t.string :acl_mode
      t.string :group_id

      t.timestamps null: false
    end
  end
end
