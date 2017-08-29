class AddOrderWeightToAnnotationLayers < ActiveRecord::Migration
  def change
    add_column :annotation_layers, :order_weight, :integer, :default => 0
  end
end
