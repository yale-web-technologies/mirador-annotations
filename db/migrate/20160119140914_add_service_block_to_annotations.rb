class AddServiceBlockToAnnotations < ActiveRecord::Migration
  def change
    add_column :annotations, :service_block, :string
  end
end
