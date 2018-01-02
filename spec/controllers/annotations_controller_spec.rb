require 'rails_helper'
require "cancan/matchers"
require "list_annotations_map"
require './spec/support/anno_auth_helper'

include Warden::Test::Helpers
Warden.test_mode!

RSpec.configure do |c|
  c.include AnnoAuthHelper
end

RSpec.describe AnnotationsController, :type => :controller do

  before(:each) do
    Rails.application.config.use_jwt_auth = true
    Rails.application.secrets.jwt_password = 'abc123'
    Rails.application.config.jwt_canvas_verification_url = 'http://testserver.com'
    allow(JWT).to receive(:decode).and_return([{"group_id" => "10", "user_id" => "100"}])
    set_anno_auth_token("someencryptedtoken")
    stub_anno_auth("10", "true", /testserver.com/)

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

    @layer1 = AnnotationLayer.create(layer_id: 'layer/1', layer_type: "sc:layer", motivation: "[oa:commenting]")
    @layer3 = AnnotationLayer.create(layer_id: 'layer/3', layer_type: "sc:layer", motivation: "[oa:translating]")
    @layer4 = AnnotationLayer.create(layer_id: 'layer/4', layer_type: "sc:layer", motivation: "[oa:translating]")

  end

  shared_examples 'invalid annotation auth' do
    before(:all) do
      @scenarios = [
        { group_id: "11", has_access: "true", endpoint: /testserver.com/ },
        { group_id: "10", has_access: "false", endpoint: /testserver.com/ },
        { group_id: nil, has_access: nil, endpoint: /testserver.com/}
      ]
    end

    it 'returns 403 when jwt auth is enabled' do
      Rails.application.config.use_jwt_auth = true

      @scenarios.each do |scenario|
        group_id, has_access, endpoint = scenario.values_at(:group_id, :has_access, :endpoint)
        stub_anno_auth(group_id, has_access, endpoint)
        request_proc.call
        expect(response.status).to eq(403)
      end
    end

    it 'returns normal code when jwt auth is disabled' do
      Rails.application.config.use_jwt_auth = false

      @scenarios.each do |scenario|
        group_id, has_access, endpoint = scenario.values_at(:group_id, :has_access, :endpoint)
        stub_anno_auth(group_id, has_access, endpoint)
        request_proc.call
        expect(response.status).to eq(normal_status)
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
        post_to_create(@annotation)
        # sort to avoid intermittent failures
        actual_lists = get_lists(Annotation.last).sort
        expected_lists = ["#{ENV['IIIF_HOST_URL']}/lists/layer/1_https://whatever.fake.edu/canvas/1"].sort
        expect(actual_lists).to eq(expected_lists)
      end

      it 'belongs to correct layer' do
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
        let(:normal_status) { 201 }
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
        expected_within = ["#{ENV['IIIF_HOST_URL']}/lists/layer/1_https://whatever.fake.edu/canvas/1"]
        expect(body["within"]).to eq(expected_within)
      end

      it 'response has tags' do
        @annotation["resource"] << @tag1
        @annotation["resource"] << @tag2
        post_to_create(@annotation)
        anno = Annotation.last
        get_to_show(get_anno_id(anno))
        expect(JSON.parse(response.body)['resource']).to eq(@annotation['resource'])
      end
    end
  end


  context 'when Put is called' do
    # Layer must be an array when posting to update
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
        put_to_update(@new_annotation, 'layer/1')
        expect(response.status).to eq(200)
      end

      it 'does not change the record count' do
        put_to_update(@new_annotation, 'layer/1')
        expect(Annotation.all.count).to eq(1)
      end


      it 'updates the motivation field' do
        @new_annotation['motivation'] = 'yale:transliterating'
        put_to_update(@new_annotation, 'layer/1')
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq(["yale:transliterating"])
      end

      it 'updates the resource field' do
        put_to_update(@new_annotation, 'layer/1')
        expect(Annotation.last['resource']).to_not eq(@annotation['resource'])
      end

      it 'updates tags' do
        num_old_tags = Annotation.last.annotation_tags.count
        put_to_update(@new_annotation, 'layer/1')
        expect(Annotation.last.annotation_tags.count).to_not match_array(num_old_tags)
      end

      it 'updates version' do
        put_to_update(@new_annotation, 'layer/1')
        expect(Annotation.last.version).to eq(2)
      end

      it 'updates layer' do
        new_layer = "layer/3"
        put_to_update(@new_annotation, new_layer)
        layers = get_layers(Annotation.last)
        expect(layers).to eq([new_layer])
      end

      it 'updates list' do
        old_lists = get_lists(Annotation.last).freeze
        put_to_update(@new_annotation, 'layer/4')
        actual_lists = get_lists(Annotation.last)
        expect(actual_lists).to_not eq(old_lists)
      end


      ATTRS = %w(@type @context resource within motivation on @id)
      ATTRS.each do |attr|
        it 'updates #{attr}' do
          put_to_update(@another_annotation, 'layer/1')
          expect(get_last_anno[attr]).to eq(@another_annotation[attr])
        end
      end

      it_behaves_like 'invalid annotation auth' do
        let(:request_proc) do
          ->() { put_to_update(@new_annotation, 'layer/1') }
        end
        let(:normal_status) { 200 }
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
        delete_to_destroy(annotation_id)
        expect(response.status).to eq(204)
      end

      it 'decreases the Annotation record count' do
        annotation_id = Annotation.last.annotation_id
        expect { delete_to_destroy(annotation_id) }
          .to change(Annotation, :count).by(-1)
      end

      it 'does not delete tags' do
        annotation_id = Annotation.last.annotation_id
        tag_count = Annotation.last.annotation_tags.count
        delete_to_destroy(annotation_id)
        expect(AnnotationTag.all.count).to eq(tag_count)
      end

      it 'deletes tag mapping' do
        annotation_id = Annotation.last.annotation_id
        tag_map_count = Annotation.last.annotation_tag_maps.count
        delete_to_destroy(annotation_id)
        expect(AnnotationTagMap.all).to_not eq(tag_map_count)
      end

      it 'deletes the list_annotations map' do
        # the list it belonged to no longer has this annotation ID
        annotation_id = Annotation.last.annotation_id
        delete_to_destroy(annotation_id)
        lists = ListAnnotationsMap.getListsForAnnotation annotation_id
        expect(lists).to eq([])
      end

      it 'versions the deletion' do
        annotation_id = Annotation.last.annotation_id
        delete_to_destroy(annotation_id)
        archived_anno = JSON.parse(AnnoListLayerVersion.last["all_content"])
        expect(archived_anno["@id"]).to eq(annotation_id)
      end

      it_behaves_like 'invalid annotation auth' do
        let(:request_proc) do
          ->() {
            post_to_create(@annotation)
            annotation_id = Annotation.last.annotation_id
            delete_to_destroy(annotation_id)
           }
        end
        let(:normal_status) { 204 }
      end
    end
  end
end

def get_anno_id(anno)
  anno.annotation_id.split('annotations/').last
end

def get_last_anno
  anno = Annotation.last
  get_to_show(get_anno_id(anno))
end

def get_layers(anno)
  layers = []
  anno.annotation_layers.each do |layer|
    layers << layer["layer_id"]
  end
  layers
end

def get_lists(anno)
  list_ids = []
  anno.annotation_lists.each do |list|
    list_ids << list["list_id"]
  end
  list_ids
end

def get_to_show(annotation_id)
  get :show, params: { id: annotation_id }
end

def post_to_create(annotation)
  post :create, params: { annotation: annotation, layer_id: 'layer/1', :format => 'json' }
end

def put_to_update(annotation, layer)
  # layer_id has to be an array when posting to update
  put :update, params: { annotation: annotation, layer_id: [layer], :format => "json" }
end

def delete_to_destroy(anno_id)
  delete :destroy, params: { id: anno_id, format: 'json' }
end
