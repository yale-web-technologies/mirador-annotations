require 'rails_helper'
#require 'shoulda/matchers'

RSpec.describe Group, type: :model do

  before (:each) do
    @grp ='{"group_id": "http://localhost:5000/groups/testGroup", "description":"test group"}'
    @group= Group.create(JSON.parse(@grp))
  end

  describe Group do
   it { is_expected.to have_many :webacls}
  end

  describe Group do
    #it { should belong_to :user }
  end
end
