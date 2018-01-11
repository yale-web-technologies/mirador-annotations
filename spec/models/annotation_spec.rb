require 'rails_helper'

RSpec.describe Annotation do
  describe 'associations' do
    subject { described_class.new }

    it { is_expected.to have_many(:annotation_tag_maps) }

    it { is_expected.to have_many(:annotation_tags) }
  end

  describe 'force_square' do
    it 'the calculated bounding box is a square and the side is the max value of width and height of the original box' do
      thumb_box = Annotation.force_square({ x: 100, y: 50, width: 100, height: 200 }, 600, 400)
      expect(thumb_box[2]).to eq([thumb_box[2], thumb_box[3]].max)
      expect(thumb_box[3]).to eq([thumb_box[2], thumb_box[3]].max)
    end

    it 'works when the calculated bounding box is contained within the image' do
      thumb_box = Annotation.force_square({ x: 100, y: 50, width: 100, height: 200 }, 600, 400)
      expect(thumb_box).to eq([100, 50, 200, 200])
    end

    it 'works when the calculated bounding box goes beyond the width of the image' do
      thumb_box = Annotation.force_square({ x: 100, y: 50, width: 100, height: 200 }, 250, 400)
      expect(thumb_box).to eq([50, 50, 200, 200])
    end

    it 'works when the calculated bounding box goes beyond the height of the image' do
      thumb_box = Annotation.force_square({ x: 100, y: 50, width: 100, height: 200 }, 600, 220)
      expect(thumb_box).to eq([100, 20, 200, 200])
    end

    it 'works when the calculated bounding box violates both the width and the height of the image' do
      thumb_box = Annotation.force_square({ x: 100, y: 50, width: 100, height: 200 }, 280, 220)
      expect(thumb_box).to eq([80, 20, 200, 200])
    end
  end
end
