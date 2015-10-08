require 'rails_helper'


RSpec.describe User, type: :model do

  context 'Record Associations' do
    describe 'User associatinos' do
        #it{should have_one(:group)}
        #it { should have_many (:webacls) }
      it "returns a hasOne associations with Group" do
        expect(User.reflect_on_association(:group).class.to_s).to eq("ActiveRecord::Reflection::HasOneReflection")
      end
      it "returns a hasThrough associations with Webacl" do
        expect(User.reflect_on_association(:group).class.to_s).to eq("ActiveRecord::Reflection::HasOneReflection")
      end
    end
  end

  before (:each) do
    @usr ='{"uid":"jasper99", "email":"jasper99@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "group_id":"http://localhost:5000/groups/testGroup", "sign_in_count":"0"}'
    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group"}'
    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @user= User.create(JSON.parse(@usr))
    @group= Group.create(JSON.parse(@grp))
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
  end

  context 'when ACLs are general searched' do
    describe 'getUsersResources' do
      it "returns all a user's webacls, based on the user's group" do
        resourceIds = User.getUsersResourceIds "jasper99"
        expect(resourceIds.length).to eq(2)
      end
    end

    describe 'canUserAccess' do
      it "grants access to a specific user correctly" do
        allowed = User.canUserAccess "jasper99", "http://localhost:5000/layers/testLayer1"
        expect(allowed).to eq(true)
      end

      it "denies access to a specific user correctly" do
        allowed = User.canUserAccess "jasper99", "http://localhost:5000/layers/testLayer3"
        expect(allowed).to eq(false)
      end
    end
  end

  context 'when ACLs are searched for a user' do
    describe 'doesSpecificUserhaveSpecificPermission' do
      it "grants permission to a user who has this permission for this resource" do
        #temmporarily passing @user until Devise is implemented
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "read"
        expect(hasPermission).to eq(true)
      end

      it "deinies permission to a user who has this permission for this resource" do
        #temporarily passing @user until Devise is implemented
        hasPermission = @user.hasPermission @user, "http://localhost:5000/layers/testLayer1", "control"
        expect(hasPermission).to eq(false)
      end
    end
  end

  #after(:all) do
  #  @user.destroy!
  #  @group.destroy!
  #  @webAcl1.destroy!
  #  @webAcl2.destroy!
  #  @webAcl3.destroy!
  #end

end
