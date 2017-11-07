require 'rails_helper'

RSpec.describe Canvas, type: :model do
  it 'has many AnnotationLists' do
    is_expected.to have_many(:annotation_lists)
  end

  it 'Annotations entries are unique' do
    anno1 = Annotation.new
    anno2 = Annotation.new
    anno3 = Annotation.new

    list1 = AnnotationList.new
    list2 = AnnotationList.new

    canvas = Canvas.new

    list1.annotations << anno1
    list1.annotations << anno2

    list2.annotations << anno2
    list2.annotations << anno3

    canvas.annotation_lists << list1
    canvas.annotation_lists << list2

    expect(canvas.annotations.length).to eq(3)
  end
end
