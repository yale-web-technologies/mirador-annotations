class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :group_id
      t.string :group_description

      t.timestamps null: false
    end
  end
end
