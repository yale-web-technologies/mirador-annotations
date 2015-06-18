class FixColumnName < ActiveRecord::Migration
  def change
    rename_column :annotation_lists, :layers, :within
  end
end
