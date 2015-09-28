require 'rails_helper'

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe User, type: :model do

  before (:each) do
    @usr ='{"uid":"jasper99", "password":"pass-word", "email":"jasper99@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "group_id":"http://localhost:5000/groups/testGroup", "sign_in_count":"0"}'
    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group"}'
    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @user = FactoryGirl.create(:jasper99)
    #@user= User.create!(JSON.parse(@usr))
    @group= Group.create(JSON.parse(@grp))
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
  end

  context 'Record Associations' do
    describe 'User associations' do
      it "returns a hasOne association with Group" do
        expect(User.reflect_on_association(:group).class.to_s).to eq("ActiveRecord::Reflection::HasManyReflection")
      end
      it "returns a hasThrough association with Webacl" do
        expect(User.reflect_on_association(:webacls).class.to_s).to eq("ActiveRecord::Reflection::ThroughReflection")
      end
    end
  end

  context 'when ACLs are general searched' do
    describe 'getUsersResources' do
      it "returns all a user's webacls, based on the user's group" do
        p "when ACLs are general searched: User.uid = #{@user.uid}"
        resourceIds = User.getUsersResourceIds "jasper99"
        expect(resourceIds.length).to eq(2)
      end
    end

    describe 'canUserAccess' do
      it "grants access to a specific user correctly" do
        p "grants access to a specific user correctly"
        allowed = User.canUserAccess "jasper99", "http://localhost:5000/layers/testLayer1"
        expect(allowed).to eq(true)
      end

      it "denies access to a specific user correctly" do
        p "denies access to a specific user correctly"
        allowed = User.canUserAccess "jasper99", "http://localhost:5000/layers/testLayer3"
        expect(allowed).to eq(false)
      end
    end
  end

  context 'when ACLs are searched for a user' do
    describe 'doesSpecificUserhaveSpecificPermission' do
      it "grants permission to a user who has this permission for this resource" do
        p 'doesSpecificUserhaveSpecificPermission'
        #temmporarily passing @user until Devise is implemented
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "read"
        expect(hasPermission).to eq(true)
      end

      it "denies permission to a user who has this permission for this resource" do
        p "denies permission to a user who has this permission for this resource"
        #temporarily passing @user until Devise is implemented
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "control"
        expect(hasPermission).to eq(false)
      end
    end
  end

  after(:each) do
    @user.delete
    @group.delete
    @webAcl1.delete
    @webAcl2.delete
    @webAcl3.delete
    @webAcl1.delete
    @webAcl2.delete
    @webAcl3.delete
  end

end