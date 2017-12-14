require  'rails_helper'

RSpec.describe AnnotationLayer, type: :model do
  it 'has many AnnotationLists' do
    is_expected.to have_many(:annotation_lists)
  end
end
