class CreateCanvasMappingOldNews < ActiveRecord::Migration
  def change
    create_table :canvas_mapping_old_news do |t|
      t.string :old_canvas_id
      t.string :new_canvas_id

      t.timestamps null: false
    end
  end
end
