class CreateWebacls < ActiveRecord::Migration[4.2]
  def change
    create_table :webacls do |t|
      t.string :resource_id
      t.string :acl_mode
      t.string :group_id

      t.timestamps null: false
    end
  end
end
