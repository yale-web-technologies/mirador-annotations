require 'rails_helper'

RSpec.describe Annotation do
  describe 'associations' do
    subject { described_class.new }

    it { is_expected.to have_many(:annotation_tag_maps) }

    it { is_expected.to have_many(:annotation_tags) } 
  end
end
