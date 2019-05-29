class CreateGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :groups do |t|
      t.string :group_id
      t.string :group_description

      t.timestamps null: false
    end
  end
end
