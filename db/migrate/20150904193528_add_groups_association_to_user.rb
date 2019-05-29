class AddGroupsAssociationToUser < ActiveRecord::Migration[4.2]
  def change
    def self.up
      add_column :groups, :user_id, :integer
      add_index 'groups', ['user_id'], :name => 'index_user_id'
    end

    def self.down
      remove_column :groups, :user_id
    end
  end
end
