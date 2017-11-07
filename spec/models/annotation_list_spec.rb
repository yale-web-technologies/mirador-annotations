require 'rails_helper'

RSpec.describe AnnotationList, type: :model do
  it 'belongs to Canvas' do
    is_expected.to belong_to(:canvas)
  end

  it 'has many AnnotationLayers' do
    is_expected.to have_many(:annotation_layers)
  end

  it 'has many Annotations' do
    is_expected.to have_many(:annotations)
  end
end
