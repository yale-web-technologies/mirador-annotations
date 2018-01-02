class AddWebaclsAssociationToGroup < ActiveRecord::Migration[4.2]
  def change
    def self.up
      add_column :webacls, :group_id, :integer
      add_index 'webacls', ['group_id'], :name => 'index_group_id'
    end

    def self.down
      remove_column :webacls, :group_id
    end
  end
end
