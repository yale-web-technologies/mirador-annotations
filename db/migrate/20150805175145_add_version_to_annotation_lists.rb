class AddVersionToAnnotationLists < ActiveRecord::Migration
  def change
    add_column :annotation_lists, :version, :integer
  end
end
