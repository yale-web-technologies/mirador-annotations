class AddVersionToAnnotationLayers < ActiveRecord::Migration
  def change
    add_column :annotation_layers, :version, :integer
  end
end
