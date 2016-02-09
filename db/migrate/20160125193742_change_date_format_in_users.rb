class ChangeDateFormatInUsers < ActiveRecord::Migration
  def change
    change_column :users, :bearerToken, :varchar
  end
end
