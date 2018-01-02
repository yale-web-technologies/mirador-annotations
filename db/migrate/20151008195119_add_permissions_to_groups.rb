class AddPermissionsToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :permissions, :text
  end
end
