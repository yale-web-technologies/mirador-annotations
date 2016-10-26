class AddOrderWeightToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :order_weight, :integer
  end
end
