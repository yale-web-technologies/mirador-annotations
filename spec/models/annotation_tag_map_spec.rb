require 'rails_helper'

RSpec.describe AnnotationTagMap do
  describe 'associations' do
    subject { described_class.new }

    it { is_expected.to belong_to(:annotation) }

    it { is_expected.to belong_to(:annotation_tag) } 
  end
end
