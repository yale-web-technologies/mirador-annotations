class FixothercontentColumnName < ActiveRecord::Migration
  def change
    rename_column :annotation_layers, :othercontent, :othercontent
  end
end
