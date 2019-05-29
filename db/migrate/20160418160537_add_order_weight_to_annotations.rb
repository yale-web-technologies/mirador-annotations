class AddOrderWeightToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :order_weight, :integer
  end
end
