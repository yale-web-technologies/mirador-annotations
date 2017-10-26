require 'rails_helper'

RSpec.describe AnnotationTag do
  describe 'associations' do
    subject { described_class.new }

    it { is_expected.to have_many(:annotations) }

    it { is_expected.to have_many(:annotation_tag_maps) } 
  end
end
