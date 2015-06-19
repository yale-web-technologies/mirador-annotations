class RenameLayersColumnTypeName < ActiveRecord::Migration
  def change
    rename_column :annotation_layers, :type, :layer_type
  end
end
