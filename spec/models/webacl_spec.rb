require 'rails_helper'

RSpec.describe Webacl, type: :model do
  before(:all) do
    @acl ='{"resource_id":"http://localhost:5000/layers/testLayer", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @webAcl= Webacl.create(JSON.parse(@acl))
  end


  context 'when webAcls is searched' do
    describe 'getAclByResource' do
      it 'returns a webAcl set' do
        #Webacl.create(JSON.parse(@acl))
        @webAcls = Webacl.getAclsByResource "http://localhost:5000/layers/testLayer"
        expect( @webAcls ).not_to eq(nil)
      end
    end

    describe 'getAclByGroupId' do
      it 'returns a webAcl set' do
        #Webacl.create(JSON.parse(@acl))
        @webAcls = Webacl.getAclsByGroup "http://localhost:5000/groups/testGroup"
        expect( @webAcls ).not_to eq(nil)
      end
    end
  end

  after(:all) do
     @webAcl.delete
  end

end
