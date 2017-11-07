class AddAnnotationListToCanvas < ActiveRecord::Migration
  def change
    add_reference :annotation_lists, :canvas, index: true, foreign_key: true
  end
end
