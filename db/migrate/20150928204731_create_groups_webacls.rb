class CreateGroupsWebacls < ActiveRecord::Migration
  def change
    create_table :groups_webacls, id: false do |t|
      t.belongs_to :group, index: :true
      t.belongs_to :webacl, index: :true
    end
  end
end
