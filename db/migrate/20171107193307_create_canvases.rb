class CreateCanvases < ActiveRecord::Migration[4.2]
  def change
    create_table :canvases do |t|

      t.timestamps null: false
    end
  end
end
