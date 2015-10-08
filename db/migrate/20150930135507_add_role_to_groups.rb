class AddRoleToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :role, :string
  end
end
