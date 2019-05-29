class ChangeDateFormatInUsers < ActiveRecord::Migration[4.2]
  def change
    change_column :users, :bearerToken, :varchar
  end
end
