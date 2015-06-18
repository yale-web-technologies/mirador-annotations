class AddWithinToAnnotationLists < ActiveRecord::Migration
  def change
    remove_column :annotation_lists, :name, :string
  end
end
