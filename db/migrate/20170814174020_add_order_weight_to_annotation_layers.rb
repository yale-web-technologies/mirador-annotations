class AddOrderWeightToAnnotationLayers < ActiveRecord::Migration[4.2]
  def change
    add_column :annotation_layers, :order_weight, :integer, :default => 0
  end
end
