require 'rails_helper'
require "cancan/matchers"
require "list_annotations_map"
require './spec/support/anno_auth_helper'

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.configure do |c|
  c.include AnnoAuthHelper
end

RSpec.describe AnnotationsController, :type => :controller do

  before(:each) do
    config   = Rails.configuration.database_configuration
    host     = config[Rails.env]["host"]
    database = config[Rails.env]["database"]
    username = config[Rails.env]["username"]
    password = config[Rails.env]["password"]

    Rails.application.secrets.jwt_password = 'abc123'
    Rails.application.config.jwt_canvas_verification_url = 'http://testserver.com'
    allow(JWT).to receive(:decode).and_return([{"group_id" => "10", "user_id" => "100"}])
    set_anno_auth_token("someencryptedtoken")
    stub_anno_auth("10", "true", /testserver.com/)

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
        id: 'https://whatever.fake.edu/annotation/1',
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
            'full' => 'https://whatever.fake.edu/canvas/1',
            'selector' => {
              "@type" => "oa:SvgSelector",
              "value" => "svg stuff"
            }
          }
        )
      )

    # add within
    @annotation["within"] = [
      "#{ENV['IIIF_HOST_URL']}/lists/list1",
      "#{ENV['IIIF_HOST_URL']}/lists/list2"
    ]

    @tag1 = {
      "@type" => "oa:Tag",
      "chars" => "chapter2"
    }
    @tag2 = {
      "@type" => "oa:Tag",
      "chars" => "scene1"
    }

  end

  shared_examples 'invalid annotation auth' do
    it 'Authentication issues with endpoint for JWT' do 
      scenarios = []
      scenarios.push({ group_id: "11", has_access: "true", endpoint: /testserver.com/})
      scenarios.push({ group_id: "10", has_access: "false", endpoint: /testserver.com/})
      scenarios.push({ group_id: nil, has_access: nil, endpoint: /testserver.com/})

      scenarios.each do |scenario|
        group_id = scenario[:group_id]
        has_access = scenario[:has_access]
        endpoint = scenario[:endpoint]
        stub_anno_auth(group_id, has_access, endpoint)
        request_proc.call
        expect(response.status).to eq(403)
      end
    end
  end

  context 'when Post is called' do
    describe 'POST annotation json' do
      
      ANNO_ATTR = {
        "resource" => Array,
        "motivation" => Array,
        "on" => Hash
      }

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

      it 'has tags' do
        # add tags to resource
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
        expect(Annotation.last.annotation_tags.length).to eq(2)
      end

      it 'sends response which has tags' do
        @annotation["resource"] << @tag1
        post_to_create(@annotation)
        response_anno = JSON.parse(response.body)
        expect(response_anno["resource"]).to eq(@annotation["resource"])
      end

      it 'belongs to correct list' do
        # Check the active record and the field is correct
        post_to_create(@annotation)
        actual_lists = get_lists(Annotation.last)
        expected_lists = ["#{ENV['IIIF_HOST_URL']}/lists/list1", "#{ENV['IIIF_HOST_URL']}/lists/list2", "#{ENV['IIIF_HOST_URL']}/lists/layer/1_https://whatever.fake.edu/canvas/1"]
        expect(actual_lists).to eq(expected_lists)
      end

      it 'belongs to correct layer' do
        # Check the active record and the field is correct
        post_to_create(@annotation)
        layers = get_layers(Annotation.last)
        expect(layers).to eq(["layer/1"])
      end

      # has proper attribute types
      ANNO_ATTR.each do |attr, type|
        it "#{attr} is in JSON format" do
          post_to_create(@annotation)
          body = JSON.parse(response.body)
          expect(body[attr]).to be_a(type)
          # resource, on, motivation should all be type JSON
        end
      end

      it_behaves_like 'invalid annotation auth', @annotation do
        let(:request_proc) do
          ->() { post_to_create(@annotation) }
        end
      end

      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Get is called' do
    describe 'GET annotation json' do

      ANNO_ATTRS = {
        "@id" => String,
        "@type" => String,
        "@context" => String,
        "resource" => Array,
        "motivation" => Array,
        "on" => Hash
      }

      before(:each) do
        # sign_in @user
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
      end

      it 'returns a 200 response' do
        get_last_anno
        expect(response.status).to eq(200)
      end

      ANNO_ATTRS.each do |attr, type|
        it "has #{attr}" do
          get_last_anno
          body = JSON.parse(response.body)
          expect(body["#{attr}"]).to be_a(type)
        end
      end

      it 'has within' do
        get_last_anno
        body = JSON.parse(response.body)
        expected_within = ["#{ENV['IIIF_HOST_URL']}/lists/list1", "#{ENV['IIIF_HOST_URL']}/lists/list2", "#{ENV['IIIF_HOST_URL']}/lists/layer/1_https://whatever.fake.edu/canvas/1"]
        expect(body["within"]).to eq(expected_within)
      end

      it 'response has tags' do
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
        anno = Annotation.last
        get :show, {format: :json, id: get_anno_id(anno)}
        expect(JSON.parse(response.body)['resource']).to eq(@annotation['resource'])
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
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
        @annotation["@id"] = Annotation.last["annotation_id"]
        @new_annotation = @annotation.clone
        @new_annotation["resource"] = IIIF::Resource.
          create(
           id: nil,
           options: {
             'chars' => 'changed'
           }
          )
        new_tag = { "@type" => "oa:Tag", "chars" => "chapter10" }
        @new_annotation["resource"] << new_tag
        sign_in @user

        @another_annotation = {
          "@type": "oa:annotation",
          "@context": "http://iiif.io/api/presentation/2/context.json",
          "resource": [
            {
              "@type": "dctypes:Text",
              "format": "text/html",
              "chars": "<p>Hello World</p>"
            }
          ],
          "within": [
            "http://blah.edu/canvas/1",
            "http://blah.edu/canvas/8"
          ],
          "motivation": [
            "oa:commenting"
          ],
          "on": {
            "@type": "oa:SpecificResource",
            "full": "http://blad.edu/canvas/1",
            "selector": {
              "@type": "oa:SvgSelector",
              "value": "<svg>somestuff</svg>"
            }
          },
          "@id": Annotation.last["annotation_id"]
        }
      end

      it 'returns a 200 response' do
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        expect(response.status).to eq(200)
      end

      it 'does not change the record count' do
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        expect(Annotation.all.count).to eq(1)
      end


      it 'updates the motivation field' do
        @new_annotation['motivation'] = 'yale:transliterating'
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq(["yale:transliterating"])
      end

      it 'updates the resource field' do
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        expect(Annotation.last['resource']).to_not eq(@annotation['resource'])
      end

      it 'updates tags' do
        num_old_tags = Annotation.last.annotation_tags.count
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        expect(Annotation.last.annotation_tags.count).to_not match_array(num_old_tags)
      end

      it 'updates version' do
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        expect(Annotation.last.version).to eq(2)
      end

      it 'updates layer' do
        # layer must be a list, but it will only read the first entry
        new_layer = ["layer/3"]
        put :update, { annotation: @new_annotation, layer_id: new_layer}, :format => "json"
        layers = get_layers(Annotation.last)
        expect(layers).to eq(new_layer)
      end

      it 'updates list' do
        old_lists = get_lists(Annotation.last).freeze
        put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json"
        actual_lists = get_lists(Annotation.last)
        expect(actual_lists).to_not eq(old_lists)
      end


      ATTRS = %w(@type @context resource within motivation on @id)
      ATTRS.each do |attr|
        it 'updates #{attr}' do
          put :update, { annotation: @another_annotation, layer_id: 'layer/1'}, :format => "json"
          expect(get_last_anno[attr]).to eq(@another_annotation[attr])
        end
      end

      it_behaves_like 'invalid annotation auth' do
        let(:request_proc) do
          ->() {  put :update, { annotation: @new_annotation, layer_id: 'layer/1'}, :format => "json" }
        end
      end

      after(:each) do
        sign_out @user
      end
    end
  end

  context 'when Delete is called' do
    describe 'Delete annotation' do
      before(:each) do
        # Add tags
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2

        post_to_create(@annotation)
      end

      it 'returns a 204 ("deleted") response' do
        annotation_id = Annotation.last.annotation_id
        delete :destroy, format: :json, id: annotation_id
        expect(response.status).to eq(204)
      end

      it 'decreases the Annotation record count' do
        annotation_id = Annotation.last.annotation_id
        expect { delete :destroy, format: :json, id: annotation_id }
          .to change(Annotation, :count).by(-1)
      end

      it 'does not delete tags' do
        annotation_id = Annotation.last.annotation_id
        tag_count = Annotation.last.annotation_tags.count
        delete :destroy, format: :json, id: annotation_id
        expect(AnnotationTag.all.count).to eq(tag_count)
      end

      it 'deletes tag mapping' do
        annotation_id = Annotation.last.annotation_id
        tag_map_count = Annotation.last.annotation_tag_maps.count
        delete :destroy, format: :json, id: annotation_id
        expect(AnnotationTagMap.all).to_not eq(tag_map_count)
      end

      it 'detelets the list_annotations map' do
        # the list it belonged to no longer has this annotation ID
        annotation_id = Annotation.last.annotation_id
        delete :destroy, format: :json, id: annotation_id
        lists = ListAnnotationsMap.getListsForAnnotation annotation_id
        expect(lists).to eq([])
      end

      it 'versions the deletion' do
        annotation_id = Annotation.last.annotation_id
        delete :destroy, format: :json, id: annotation_id
        archived_anno = JSON.parse(AnnoListLayerVersion.last["all_content"])
        expect(archived_anno["@id"]).to eq(annotation_id)
      end

      it_behaves_like 'invalid annotation auth' do
        let(:request_proc) do
          ->() {
            annotation_id = Annotation.last.annotation_id
            delete :destroy, format: :json, id: annotation_id
           }
        end
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

def get_anno_id(anno)
  anno.annotation_id.split('annotations/').last
end

def get_last_anno
  anno = Annotation.last
  get :show, {format: :json, id: get_anno_id(anno)}
end

def get_layers(anno)
  anno_id = "#{ENV['IIIF_HOST_URL']}/annotations/" + get_anno_id(anno)
  lists = ListAnnotationsMap.getListsForAnnotation(anno_id)
  layers = []
  lists.each do |list|
    layers << LayerListsMap.getLayersForList(list)
  end
  layers.flatten!
end

def get_lists(anno)
  anno_id = "#{ENV['IIIF_HOST_URL']}/annotations/" + get_anno_id(anno)
  ListAnnotationsMap.getListsForAnnotation(anno_id)
end