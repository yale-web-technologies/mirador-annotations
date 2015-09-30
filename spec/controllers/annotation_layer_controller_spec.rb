require 'rails_helper'
require "cancan/matchers"

include Warden::Test::Helpers
Warden.test_mode!
include Devise::TestHelpers

RSpec.describe AnnotationLayerController, type: :controller do

    context 'when Post is called' do
      describe 'POST annotation json' do
        before(:each) do
          @annoLayerString ='{"label": "Layer 2", "motivation": "yale:transcribing", "license": "http://creativecommons.org/licenses/by/4.0/", "@type": "sc:Layer", "@context": "http://iiif.io/api/presentation/2/context.json", "otherContent": "http://localhost:5000/lists/1"}'
        end
        it 'returns a 201 ("created") response' do
          post :create, JSON.parse(@annoLayerString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
          expect(response.status).to eq(201)
        end

        it 'creates a new Layer' do
          expect { post :create, JSON.parse(@annoLayerString) }.to change(AnnotationLayer, :count).by(1)
        end

        it 'creates an @id for the returned layer' do
          post :create, JSON.parse(@annoLayerString)
          expect(response.status).to eq(201)
          json = JSON.parse(response.body)
          expect(json['@id']).to be_truthy
        end

        it 'assigns the version' do
          post :create, JSON.parse(@annoLayerString)
          @annotationLayer = AnnotationLayer.last()
          expect(@annotationLayer['version']).to eq (1)
        end

        it 'does not fail validation if otherContent is nil' do
          json = JSON.parse(@annoLayerString)
          json['otherContent'] = nil
          post :create, json
          expect(response.status).to eq(201)
        end
      end

    end

    context 'when Get is called' do
      describe 'GET annotation json' do
        before(:each) do
          @annoLayerString ='{"label": "Layer 2", "motivation": "yale:transcribing", "license": "http://creativecommons.org/licenses/by/4.0/", "@type": "sc:Layer", "@context": "http://iiif.io/api/presentation/2/context.json", "otherContent": "http://localhost:5000/lists/1"}'
        end

        it 'returns a 200 response' do
          post :create, JSON.parse(@annoLayerString)
          @layer = AnnotationLayer.last()
          @layerUID = @layer.layer_id.split('layers/').last
          get :show, {format: :json, id: @layerUID}
          expect(response.status).to eq(200)
        end

        it 'retrieves motivation correctly' do
          post :create, JSON.parse(@annoLayerString)
          @layer = AnnotationLayer.last()
          @layerUID = @layer.layer_id.split('layers/').last
          get :show, {format: :json, id: @layerUID}
          responseJSON = JSON.parse(response.body)
          expect(responseJSON['motivation']).to eq("yale:transcribing")
        end
      end
    end


    context 'when Put is called' do
      describe 'Put annotationList json' do
        before(:each) do
          @annoLayerString ='{"label": "Layer 2", "motivation": "yale:transcribing", "license": "http://creativecommons.org/licenses/by/4.0/", "@type": "sc:Layer", "@context": "http://iiif.io/api/presentation/2/context.json", "otherContent": "http://localhost:5000/lists/1"}'
          post :create, JSON.parse(@annoLayerString)
          @layer = AnnotationLayer.last()
          #@layer = post :create, JSON.parse(@annoLayerString)
          @layerJSON = JSON.parse(@annoLayerString)
          @layerJSON['@id'] = @layer.layer_id
        end

        it 'does not change the record count' do
          @layerJSON['label'] = 'label update'
          expect { put :update, @layerJSON }.to change(AnnotationLayer, :count).by(0)
        end

        it 'returns a 200 response' do
          @layerJSON['label'] = 'label update'
          put :update, @layerJSON, :format => 'json'
          expect(response.status).to eq(200)
        end

        it 'updates the label field' do
          @layerJSON['label'] = 'label update'
          put :update, @layerJSON, :format => 'json'
          responseJSON = JSON.parse(response.body)
          expect(responseJSON['label']).to eq("label update")
        end

        it 'fails validation correctly' do
          @layerJSON['label'] = nil
          put :update, @layerJSON, :format => 'json'
          expect(response.status).to eq(422)
        end


        it 'creates a version correctly' do
          @layerJSON['label'] = 'label update'
          put :update, @layerJSON, :format => 'json'
          @layer = AnnotationLayer.last()
          @version = AnnoListLayerVersion.last()
          expect(@layer.version).to eq(2)
          expect(@version.all_id).to eq(@layer.layer_id)
          expect(@version.all_type.downcase).to eq("sc:layer")
          expect(@version.all_version).to eq(@layer.version-1)
        end

      end
    end

    context 'when Delete is called' do
      describe 'Delete annotation' do
        before(:each) do
          @layerString ='{"label": "Layer 2", "motivation": "yale:transcribing", "license": "http://creativecommons.org/licenses/by/4.0/", "@type": "sc:Layer", "@context": "http://iiif.io/api/presentation/2/context.json", "otherContent": "http://localhost:5000/lists/1"}'
          post :create, JSON.parse(@layerString)
          @layer = AnnotationLayer.last()
          @layerUID = @layer.layer_id.split('layers/').last
        end

        it 'returns a 201 ("created") response' do
          delete :destroy, format: :json, id: @layerUID
          expect(response.status).to eq(204)
        end

        it 'decreases the Layer record count' do
          expect {delete :destroy, {format: :json, id: @layerUID} }.to change(AnnotationLayer, :count).by(-1)
        end

        it 'deletes the Layer record' do
          delete :destroy, format: :json, id: @layerUID
          expect(@layerDeleted = AnnotationLayer.where(layer_id: @layer.layer_id).first).to eq(nil)
        end

        it 'creates a version correctly' do
          delete :destroy, format: :json, id: @layerUID
          @version = AnnoListLayerVersion.last()
          expect(@layer.version).to eq(1)
          expect(@version.all_id).to eq(@layer.layer_id)
          expect(@version.all_type.downcase).to eq("sc:layer")
          expect(@version.all_version).to eq(@layer.version)
        end

      end
    end

end