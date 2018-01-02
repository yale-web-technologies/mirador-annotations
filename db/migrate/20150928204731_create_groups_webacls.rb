class CreateGroupsWebacls < ActiveRecord::Migration[4.2]
  def change
    create_table :groups_webacls, id: false do |t|
      t.belongs_to :group, index: :true
      t.belongs_to :webacls, index: :true
    end
  end
end
