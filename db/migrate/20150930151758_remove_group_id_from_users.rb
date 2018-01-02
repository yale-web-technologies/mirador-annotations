class RemoveGroupIdFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :group_id, :string
  end
end
