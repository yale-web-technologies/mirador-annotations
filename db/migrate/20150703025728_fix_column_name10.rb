class FixColumnName10 < ActiveRecord::Migration
  def change
    rename_column :annotation_layers, :otherContent, :othercontent
  end
end
