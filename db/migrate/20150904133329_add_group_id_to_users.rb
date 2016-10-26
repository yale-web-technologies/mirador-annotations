class AddGroupIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :group_id, :string
  end
end
