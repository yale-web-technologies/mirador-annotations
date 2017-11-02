require 'rails_helper'
require "cancan/matchers"

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe AnnotationsController, :type => :controller do

  before(:each) do
    config   = Rails.configuration.database_configuration
    host     = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]
    puts "TOTOTO env #{Rails.env}"
    puts "TOTOTO host #{host}"
    puts "TOTOTO database #{database}"
    puts "TOTOTO annos #{Annotation.count}"

    @annoList1 ='{"list_id": "http://localhost:5000/lists/list1", "list_type": "sc:AnnotationList", "label":"transcription layer 1 list 1"}'
    @annotation_list1 = AnnotationList.create(JSON.parse(@annoList1))
    @annoList2 ='{"list_id": "http://localhost:5000/lists/list2", "list_type": "sc:AnnotationList", "label":"transcription layer 1 list 2"}'
    @annotation_list2 = AnnotationList.create(JSON.parse(@annoList2))

    @usr ='{"uid":"jasper99", "password":"pass-word", "email":"jasper99@yale.edu", "encrypted_password":"7KVcbLRkKU15XiCRlTGuj0raudw+pl+SaGVnm456LoE", "provider":"cas", "sign_in_count":"0"}'
    @grp='{"group_id": "http://localhost:5000/groups/testGroup", "group_description":"test group"}'
    @usrgrp = '{"user_id":"jasper99","group_id":"http://localhost:5000/groups/testGroup"}'
    @usrgrp2 = '{"user_id":"jasper99","group_id":"http://localhost:5000/groups/testGroup3"}'


    @aclList1 ='{"resource_id":"http://localhost:5000/lists/list1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @webAclList1= Webacl.create(JSON.parse(@aclList1))
    @aclList1w ='{"resource_id":"http://localhost:5000/lists/list1", "acl_mode": "write", "group_id": "http://localhost:5000/groups/testGroup"}'
    @webAclList1w= Webacl.create(JSON.parse(@aclList1w))
    @aclList2 ='{"resource_id":"http://localhost:5000/lists/list2", "acl_mode": "prognosticate", "group_id": "http://localhost:5000/groups/testGroup2"}'
    @webAclList2= Webacl.create(JSON.parse(@aclList2))

    @acl1 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl2 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "create", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl3 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "update", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl4 ='{"resource_id":"http://localhost:5000/layers/testLayer1", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup"}'

    @acl5 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl6 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "create", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl7 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "update", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl8 ='{"resource_id":"http://localhost:5000/layers/testLayer2", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup"}'

    @acl9 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @acl10 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "create", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @acl11 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "update", "group_id": "http://localhost:5000/groups/testGroup3"}'
    @acl12 ='{"resource_id":"http://localhost:5000/layers/testLayer3", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup3"}'


    @acl13 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "read", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl14 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "create", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl15 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "update", "group_id": "http://localhost:5000/groups/testGroup"}'
    @acl16 ='{"resource_id":"http://localhost:5000/annotations/testAnnotation", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup"}'

    @user= User.create!(JSON.parse(@usr))
    @group= Group.create(JSON.parse(@grp))
    @user.groups.create JSON.parse(@usrgrp)
    @webAcl1= Webacl.create(JSON.parse(@acl1))
    @webAcl2= Webacl.create(JSON.parse(@acl2))
    @webAcl3= Webacl.create(JSON.parse(@acl3))
    @webAcl4= Webacl.create(JSON.parse(@acl4))

    @webAcl5= Webacl.create(JSON.parse(@acl5))
    @webAcl6= Webacl.create(JSON.parse(@acl6))
    @webAcl7= Webacl.create(JSON.parse(@acl7))
    @webAcl8= Webacl.create(JSON.parse(@acl8))

    @webAcl9= Webacl.create(JSON.parse(@acl9))
    @webAcl10= Webacl.create(JSON.parse(@acl10))
    @webAcl11= Webacl.create(JSON.parse(@acl11))
    @webAcl12= Webacl.create(JSON.parse(@acl12))

    @webAcl13= Webacl.create(JSON.parse(@acl13))
    @webAcl14= Webacl.create(JSON.parse(@acl14))
    @webAcl15= Webacl.create(JSON.parse(@acl15))
    @webAcl16= Webacl.create(JSON.parse(@acl16))


    @annotation = IIIF::Annotation.
      create(
      id: 9999,
      resource: IIIF::Resource.
        create(
          id: nil, 
          options: {
            'chars' => 'Anno 1'
          }
        ),
      target: IIIF::Target.
        create(
          targeting_canvas: true,
          options: {
          'full' => '/canvas/1'
          }
        )
      )

    @tag1 = {
      "@type": "oa:Tag",
      "chars": "chapter2"
    }
    @tag2 = {
      "@type": "oa:Tag",
      "chars": "scene1"
    }

  end

  context 'when Post is called' do
    describe 'POST annotation json' do
      before(:each) do
        sign_in @user
      end

      it 'returns a 201 ("created") response' do
        post_to_create(@annotation)
        expect(response.status).to eq(201)
      end

      it 'creates a new Annotation' do
        post_to_create(@annotation)
        # Can't determine what the annotation_id will be (hash)
        # so just get the latest ActiveRecord entry
        resource = JSON.parse(Annotation.last["resource"])
        target = Annotation.last["target"]
        expect(resource).to eq(@annotation["resource"])
        expect(target).to eq(@annotation["target"])
      end

      it 'creates an @id for the returned annotation' do
        post_to_create(@annotation)
        response_anno = JSON.parse(response.body)
        expect(response_anno['@id']).to be_truthy
      end

      it 'assigns the version' do
        post_to_create(@annotation)
        expect(Annotation.last['version']).to eq (1)
      end

      xit 'fails validation if motivation is nil' do
        @annotation['motivation'] = nil
        post_to_create(@annotation)
        expect(response.status).to eq(422)
      end

      xit 'does not fail validation if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        expect(response.status).to eq(201)
      end

      xit 'updates the map if within is not nil' do
        annoJSON = JSON.parse(@annoString)
        post :create, annoJSON
        json = JSON.parse(response.body)
        lists = ListAnnotationsMap.getListsForAnnotation json['@id']
        expect(lists).not_to eq(nil)
        expect(lists).to eq(annoJSON['within'])
      end

      xit 'creates the right number of webacls' do
        annoJSON = JSON.parse(@annoString)
        post :create, annoJSON
        json = JSON.parse(response.body)
        webacls = Webacl.getAclsByResource json['@id']
        expect(webacls).not_to eq(nil)
        expect(webacls.count).to eq(3)
      end

      it 'has tags' do
        # add tags to resource
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
        expect(Annotation.last.annotation_tags.length).to eq(2)
      end


      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Get is called' do
    describe 'GET annotation json' do
      before(:each) do
        sign_in @user
      end

      it 'returns a 200 response' do
        post_to_create(@annotation)
        anno = Annotation.last()
        annoUID = anno.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end

      xit 'retrieves motivation correctly' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transcribing")
      end

      xit 'does not fail if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end

      after(:each) do
        sign_out @user
      end
    end
  end


  context 'when Put is called' do
    describe 'Put annotation json' do
      before(:each) do
        # Need to update tags and text (resource chars)
        post_to_create(@annotation)
        @new_annotation = @annotation.clone
        @new_annotation["resource"] = IIIF::Resource.
          create(
           id: nil,
           options: {
             'chars' => 'changed'
           }
          )
        new_tag = { "@type": "oa:Tag", "chars": "chapter10" }
        @new_annotation["resource"] << new_tag
        sign_in @user
      end

      describe 'abilities' do
        #ability = Ability.new(@user)
        #ability.should be_able_to(:read, Annotation)
        #subject(:ability) { Ability.new(@user) }
        #it {is_expected.not_to_be_able_to :read, Annotation}
      end
      
      it 'returns a 200 response' do
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json" 
        expect(response.status).to eq(200)
      end

      xit 'does not change the record count' do
        @annoJSON['motivation'] = 'yale:transliterating'
        expect { put :update, @annoJSON }.to change(Annotation, :count).by(0)
      end


      xit 'updates the motivation field' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transliterating")
      end

      xit 'fails validation correctly' do
        @annoJSON['motivation'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(422)
      end

      xit 'does not fail if  if [within] is blank' do
        @annoJSON['within'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(200)
      end

      xit 'updates the list_annotations map correctly'  do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq(@annoJSON['within'])
      end

      xit 'creates a version correctly' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @annotation = Annotation.last()
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(2)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version-1)
      end
      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Delete is called' do
    describe 'Delete annotation' do
      before(:each) do
        @annoString =#'{"annotation_id":"http://test.host/annotations/testAnnotation",
                      '{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/list1","http://localhost:5000/lists/list2"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'

        # sign_in @user
        # post :create, JSON.parse(@annoString)
        # @annotation = Annotation.last()
        # @aclDelete ='{"resource_id":"' + @annotation.annotation_id + '", "acl_mode": "delete", "group_id": "http://localhost:5000/groups/testGroup"}'
        # #p @aclDelete.to_s
        # @webAclDel = Webacl.create(JSON.parse(@aclDelete))
      end

      xit 'returns a 204 ("deleted") response' do
        #annoUID = @annotation.annotation_id.split('annotations/').last
        annoUID = @annotation.annotation_id
        delete :destroy, format: :json, id: annoUID
        expect(response.status).to eq(204)
      end

      xit 'decreases the Annotation record count' do
        #annoUID = @annotation.annotation_id.split('annotations/').last
        annoUID = @annotation.annotation_id
        expect {delete :destroy, {format: :json, id: annoUID} }.to change(Annotation, :count).by(-1)
      end

      xit 'deletes the Annotation record' do
        #annoUID = @annotation.annotation_id.split('annotations/').last
        annoUID = @annotation.annotation_id
        delete :destroy, format: :json, id: annoUID
        expect(@annotationDeleted = Annotation.where(annotation_id: @annotation.annotation_id).first).to eq(nil)
      end

      xit 'deletes the list_annotations map correctly' do
        #annoUID = @annotation.annotation_id.split('annotations/').last
        annoUID = @annotation.annotation_id
        delete :destroy, format: :json, id: annoUID
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq([])
      end

      xit 'creates a version correctly' do
        #annoUID = @annotation.annotation_id.split('annotations/').last
        annoUID = @annotation.annotation_id
        delete :destroy, format: :json, id: annoUID
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(1)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version)
      end

      after(:each) do
        sign_out @user
      end
    end
  end

  after(:each) do
    @webAcl1.destroy
    @webAcl2.destroy
    @webAcl3.destroy
    @webAcl4.destroy
    @webAcl5.destroy
    @webAcl6.destroy
    @webAcl7.destroy
    @webAcl8.destroy
    @webAcl9.destroy
    @webAcl10.destroy
    @webAcl11.destroy
    @webAcl12.destroy
    @webAcl13.destroy
    @webAcl14.destroy
    @webAcl15.destroy
    @webAcl16.destroy
    @webAclList1.destroy
    @group.destroy
    @annotation_list1.destroy
    @annotation_list2.destroy
    @user.destroy
  end

end

def post_to_create(annotation)
  post :create, { annotation: annotation, layer_id: 'layer/1' }, :format => 'json'
end
