require 'rails_helper'

RSpec.describe Site, type: :model do

  before (:each) do
    @grpProjEditor='{"group_id":"http://localhost:5000/groups/testGroup", "group_description":"test group for project editor","site_id":"http://localhost:5000/sites/testsite","role":"project_editor"}'
    @grpContributor='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group for contributor","site_id":"http://localhost:5000/sites/testsite","role":"contributor"}'
    @site='{"site_id":"http://localhost:5000/sites/testsite", "site_title":"Site for Test Project", "site_description":"This is the Test Project Site"}'

    @groupProjEd = Group.create(JSON.parse(@grpProjEditor))
    @groupContributor = Group.create(JSON.parse(@grpContributor))
    @siteTest = Site.create(JSON.parse(@site))
  end


  context 'Record Associations' do
    describe 'Site associations' do
      it "returns a hasMany association with Group" do
        expect(Site.reflect_on_association(:groups).class.to_s).to eq("ActiveRecord::Reflection::HasManyReflection")
      end
    end
  end

  context 'Site Associated Groups' do
    describe 'getSitesGroupByRole' do
      it "returns a site's group, based on the role" do
        group = @siteTest.findGroupforSiteRole "contributor"
        expect(group).to be_instance_of(Group)
      end
      it "returns correct site's group, based on the role" do
        group = @siteTest.findGroupforSiteRole "project_editor"
        expect(group.group_description).to eq("test group for project editor")
      end
    end
  end

end





