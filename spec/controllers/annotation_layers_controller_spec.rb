require 'rails_helper'
require "cancan/matchers"

include Warden::Test::Helpers
Warden.test_mode!

RSpec.describe AnnotationLayersController, type: :controller do

    context 'when Post is called' do
      describe 'POST annotation json' do
        before(:each) do
          @layer = {
            '@context' => 'http://iiif.io/api/presentation/2/context.json',
            '@type' => 'sc:Layer',
            'label' => 'Layer 2',
            'otherContent' => [ 'http://localhost:5000/lists/1' ]
          }
        end
        it 'returns a 201 ("created") response' do
          post_to_create(@layer)
          expect(response.status).to eq(201)
        end

        it 'creates a new Layer' do
          expect { post_to_create(@layer) }.to change(AnnotationLayer, :count).by(1)
        end

        it 'creates an @id for the returned layer' do
          post_to_create(@layer)

          expect(response.status).to eq(201)
          json = JSON.parse(response.body)
          expect(json['@id']).to be_truthy
        end

        it 'assigns the version' do
          post_to_create(@layer)
          @annotationLayer = AnnotationLayer.last()
          expect(@annotationLayer['version']).to eq (1)
        end

        it 'does not fail validation if otherContent is nil' do
          layer = @layer
          layer[:otherContent] = nil
          post_to_create(layer)
          expect(response.status).to eq(201)
        end
      end

    end

    context 'when Get is called' do
      describe 'GET annotation json' do
        before(:each) do
          @layer = {
            '@context': 'http://iiif.io/api/presentation/2/context.json',
            '@type': 'sc:Layer',
            label: 'Layer 2',
            otherContent: [ 'http://localhost:5000/lists/1' ]
          }
        end

        it 'returns a 200 response' do
          post_to_create(@layer)
          @layer = AnnotationLayer.last()
          @layerUID = @layer.layer_id.split('layers/').last
          get_to_show(@layerUID)
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when Put is called' do
      describe 'Put annotationList json' do
        before(:each) do
          AnnotationLayer.delete_all
          @params = IIIF::Layer.create(id: '/layer/1', options: {
            'label' => 'Old Label'
          })
          layer = AnnotationLayer.create_from_iiif(@params)
          @old_id = layer.layer_id
        end

        it 'does not change the record count' do
          params = @params.merge('@id' => @old_id, 'label' => 'New Label')
          expect { put_to_update(params) }.to change(AnnotationLayer, :count).by(0)
        end

        it 'returns a 200 response' do
          params = @params.merge('@id' => @old_id, 'label' => 'New Label')
          put_to_update(params)
          expect(response.status).to eq(200)
        end

        it 'updates the label field' do
          params = @params.merge('@id' => @old_id, 'label' => 'New Label')
          put_to_update(params)
          layer = JSON.parse(response.body)
          expect(layer['label']).to eq("New Label")
        end

        it 'fails validation correctly' do
          params = @params.clone
          params.delete('label')
          put_to_update(params)
          expect(response.status).to eq(422)
        end

        it 'creates a version correctly' do
          params = @params.merge('@id' => @old_id, 'label' => 'New Layer')
          put_to_update(params)
          layer = AnnotationLayer.last()
          version = AnnoListLayerVersion.last()
          expect(layer.version).to eq(2)
          expect(version.all_id).to eq(layer.layer_id)
          expect(version.all_type).to eq("sc:Layer")
          expect(version.all_version).to eq(layer.version - 1)
        end
      end
    end

    context 'when Delete is called' do
      describe 'Delete annotation' do
        before(:each) do
          params = {
            label: 'Layer 2',
            '@type': 'sc:Layer',
            '@context': 'http://iiif.io/api/presentation/2/context.json',
            otherContent: ['http://localhost:5000/lists/1']
          }
          post_to_create(params)
          @layer = AnnotationLayer.last()
          @layer_uid = @layer.layer_id.split('layers/').last
        end

        it 'returns a 201 ("created") response' do
          delete_to_destroy(@layer_uid)
          expect(response.status).to eq(204)
        end

        it 'decreases the Layer record count' do
          delete_to_destroy(@layer_uid)
        end

        it 'deletes the Layer record' do
          delete_to_destroy(@layer_uid)
          expect(@layerDeleted = AnnotationLayer.where(layer_id: @layer.layer_id).first).to eq(nil)
        end

        it 'creates a version correctly' do
          delete_to_destroy(@layer_uid)
          @version = AnnoListLayerVersion.last()
          expect(@layer.version).to eq(1)
          expect(@version.all_id).to eq(@layer.layer_id)
          expect(@version.all_type).to eq("sc:Layer")
          expect(@version.all_version).to eq(@layer.version)
        end

      end
    end

    def get_to_show(layer_id)
      get :show, params: { id: layer_id }
    end

    def post_to_create(layer)
      post :create, params: { annotation_layer: layer, format: 'json' }
    end

    def put_to_update(layer)
      # Setting id to 0 is just to match a route; the value is ignored by the server code.
      put :update, params: { id: 0, annotationLayer: layer, format: 'json' }
    end

    def delete_to_destroy(layer_id)
      delete :destroy, params: { id: layer_id, format: 'json' }
    end
end
