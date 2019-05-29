class AddVersionToAnnotationLayers < ActiveRecord::Migration[4.2]
  def change
    add_column :annotation_layers, :version, :integer
  end
end
