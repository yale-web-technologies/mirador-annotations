class AddGroupIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :group_id, :string
  end
end
