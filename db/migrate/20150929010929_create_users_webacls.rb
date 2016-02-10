class CreateUsersWebacls < ActiveRecord::Migration
  def change
    #create_table :users_webacls, id: :false do |t|
    create_table :users_webacls do |t|
      t.belongs_to :user, index: :true
      t.belongs_to :group, index: :true
      t.belongs_to :webacl, index: :true
    end
  end
end
