class AddSiteIdToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :site_id, :string
  end
end
