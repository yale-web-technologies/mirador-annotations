class RenameColumnName < ActiveRecord::Migration
  def change
    rename_column :annotation_lists, :@id, :list_id
  end
end
