class AddVersionToAnnotationLists < ActiveRecord::Migration[4.2]
  def change
    add_column :annotation_lists, :version, :integer
  end
end
