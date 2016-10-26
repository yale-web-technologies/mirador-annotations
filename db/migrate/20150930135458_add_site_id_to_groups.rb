class AddSiteIdToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :site_id, :string
  end
end
