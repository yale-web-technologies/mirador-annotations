class CreateCanvases < ActiveRecord::Migration
  def change
    create_table :canvases do |t|

      t.timestamps null: false
    end
  end
end
