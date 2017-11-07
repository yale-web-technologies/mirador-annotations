require 'rails_helper'

RSpec.describe LayerListsMap do
  describe 'associations' do
    subject { described_class.new }

    it { is_expected.to belong_to(:annotation_layer) }

    it { is_expected.to belong_to(:annotation_list) } 
  end
end
