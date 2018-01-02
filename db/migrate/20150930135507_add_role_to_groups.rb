class AddRoleToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :role, :string
  end
end
