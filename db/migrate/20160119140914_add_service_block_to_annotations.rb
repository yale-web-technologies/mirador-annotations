class AddServiceBlockToAnnotations < ActiveRecord::Migration[4.2]
  def change
    add_column :annotations, :service_block, :string
  end
end
