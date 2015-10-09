class AddPermissionsToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :permissions, :text
  end
end
