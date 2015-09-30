require 'rails_helper'

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe User, type: :model do

  before (:all) do
    @usr ='{"uid":"jasper99", "password":"pass-word", "email":"jasper99@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "sign_in_count":"0"}'
    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group"}'
    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'
    #@user= User.create!(JSON.parse(@usr))
    @user = FactoryGirl.create(:jasper99)

    @usrgrp = '{"user_id":"jasper99","group_id":"http://localhost:5000/groups/testGroup"}'
    @usrgrp2 = '{"user_id":"jasper99","group_id":"http://localhost:5000/groups/testGroup3"}'
    @user.groups.create JSON.parse(@usrgrp)
    #@user.groups.create JSON.parse(@usrgrp2)

    @group= Group.create(JSON.parse(@grp))
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
  end

  context 'Record Associations' do
    describe 'User associations' do
      it "returns a hasMany association with Group" do
        expect(User.reflect_on_association(:groups).class.to_s).to eq("ActiveRecord::Reflection::HasAndBelongsToManyReflection")
        #expect(User.reflect_on_association(:groups).class.to_s).to eq("ActiveRecord::Reflection::HasManyReflection")
      end
      it "returns a hasThrough association with Webacl" do
        expect(User.reflect_on_association(:webacls).class.to_s).to eq("ActiveRecord::Reflection::HasAndBelongsToManyReflection")
        #expect(User.reflect_on_association(:webacls).class.to_s).to eq("ActiveRecord::Reflection::ThroughReflection")
      end
    end
  end

  context 'when ACLs are general searched' do
    describe 'getUsersResources' do
      it "returns all a user's webacls, based on the user's group" do
        resourceIds = User.getUsersResourceIds @user
        expect(resourceIds.length).to eq(2)
      end
    end

    describe 'canUserAccess' do
      it "grants access to a specific user correctly" do
        allowed = User.canUserAccess @user, "http://localhost:5000/layers/testLayer1"
        expect(allowed).to eq(true)
      end

      it "denies access to a specific user correctly" do
        allowed = User.canUserAccess @user, "http://localhost:5000/layers/testLayer3"
        expect(allowed).to eq(false)
      end
    end
  end

  context 'when ACLs are searched for a user' do
    describe 'doesSpecificUserhaveSpecificPermission' do
      it "grants permission to a user who has this permission for this resource" do
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "read"
        expect(hasPermission).to eq(true)
      end

      it "denies permission to a user who has this permission for this resource" do
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "control"
        expect(hasPermission).to eq(false)
      end
    end
  end

  after(:all) do
    #@user.destroy
    #@group.destroy
    #@webAcl1.destroy
    #@webAcl2.destroy
    #@webAcl3.destroy
  end

end