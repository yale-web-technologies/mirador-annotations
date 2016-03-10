require 'rails_helper'

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe Group, type: :model do

  before (:each) do
    @usr ='{"uid":"jasper99", "password":"pass-word", "email":"jasper99@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "sign_in_count":"0"}'
    @usr2 ='{"uid":"jasper77", "password":"pass-word", "email":"jasper77@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "sign_in_count":"0"}'
    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group","permissions":"[read,create,update]","site_id":"testSite1","role":"contributor"}'
    @usrgrp = '{"user_id":"jasper99","group_id":"http://localhost:5000/groups/testGroup"}'
    @usrgrp2 = '{"user_id":"jasper77","group_id":"http://localhost:5000/groups/testGroup2"}'
    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'

    @user= User.create!(JSON.parse(@usr))
    @user2= User.create!(JSON.parse(@usr2))
    #@user = FactoryGirl.create(:jasper99)
    @group= Group.create(JSON.parse(@grp))
    @userGroup1 = @group.users.create JSON.parse(@usrgrp)
    #@userGroup2 = @group.users.create JSON.parse(@usrgrp2)
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
  end

  context 'Record Associations' do
    describe 'Group associations' do
      it "returns a hasMany association with Group" do
        expect(Group.reflect_on_association(:users).class.to_s).to eq("ActiveRecord::Reflection::HasAndBelongsToManyReflection")
      end
      it "returns a hasMany association with Webacl" do
        expect(Group.reflect_on_association(:webacls).class.to_s).to eq("ActiveRecord::Reflection::HasManyReflection")
      end
    end
  end

  context 'Groups Associated resources' do
    describe 'getGroupsResources' do
      it "returns all a group's webacls, based on the group" do
        resourceIds = Group.getGroupsResourceIds @group
        expect(resourceIds.length).to eq(2)
      end
    end
  end

  context 'Groups Associated users' do
    describe 'getGroupsUsers' do
      it "returns all a group's users, based on the group" do
        userIds = Group.getGroupsUserIds @group
        expect(userIds.length).to eq(1)
      end
    end
  end

  context 'Groups default permissions' do
    describe 'get Groups Permissions' do
      it "stores and returns the group's default permissions" do
        permissions = @group.permissions.split(",")
        expect(permissions.count).to eq(3)
      end
    end
  end

  after(:each) do
    @user.destroy
    @group.destroy
    @userGroup1.destroy
    #@userGroup2.destroy
    @webAcl1.destroy
    @webAcl2.destroy
    @webAcl3.destroy
  end

end
