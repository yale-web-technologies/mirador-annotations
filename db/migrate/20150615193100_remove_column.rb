class RemoveColumn < ActiveRecord::Migration
  def change
    remove_column :annotation_lists, :name
  end
end
