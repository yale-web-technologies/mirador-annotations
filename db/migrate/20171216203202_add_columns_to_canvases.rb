class AddColumnsToCanvases < ActiveRecord::Migration[5.1]
  def change
    add_column :canvases, :iiif_canvas_id, :string
    add_index :canvases, :iiif_canvas_id
    add_column :canvases, :label, :string
  end
end
