require 'rails_helper'

RSpec.describe AnnotationListsController, type: :controller do

  before(:all) do
    @annoLayer ='{"layer_id": "http://localhost:5000/layers/testLayer", "label": "Layer 2", "motivation": "yale:transcribing", "license": "http://creativecommons.org/licenses/by/4.0/", "layer_type": "sc:Layer", "@context": "http://iiif.io/api/presentation/2/context.json"}'
    @annotationLayer = AnnotationLayer.create(JSON.parse(@annoLayer))
  end

  context 'when Post is called' do
    describe 'POST annotation json' do
        before(:each) do
          @annoListString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json", "label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/testLayer"]}'
        end

      it 'returns a 201 ("created") response' do
        post :create, JSON.parse(@annoListString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
        expect(response.status).to eq(201)
      end

      it 'creates a new List' do
        expect { post :create, JSON.parse(@annoListString) }.to change(AnnotationList, :count).by(1)
      end

      it 'creates an @id for the returned list' do
        post :create, JSON.parse(@annoListString)
        expect(response.status).to eq(201)
        json = JSON.parse(response.body)
        expect(json['@id']).to be_truthy
      end

      it 'assigns the version' do
        post :create, JSON.parse(@annoListString)
        @annotationList = AnnotationList.last()
        expect(@annotationList['version']).to eq (1)
      end

      it 'fails validation if motivation is nil' do
        json = JSON.parse(@annoListString)
        json['label'] = nil
        post :create, json
        expect(response.status).to eq(422)
      end

      it 'does not fail validation if within is nil' do
        json = JSON.parse(@annoListString)
        json['within'] = nil
        post :create, json
        expect(response.status).to eq(201)
      end

      it 'updates the map if within is not nil' do
        json = JSON.parse(@annoListString)
        post :create, json
        json = JSON.parse(response.body)
        layers = LayerListsMap.getLayersForList json['@id']
        expect(layers).not_to eq(nil)
        expect(layers).to eq(json['within'])
      end

    end
  end

  context 'when Get is called' do
    describe 'GET annotation json' do
      before(:each) do
        @listString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json", "label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/testLayer"]}'
      end

      it 'returns a 200 response' do
        post :create, JSON.parse(@listString)
        @list = AnnotationList.last()
        @listUID = @list.list_id.split('lists/').last
        get :show, {format: :json, id: @listUID}
        expect(response.status).to eq(200)
      end

      it 'retrieves label correctly' do
        post :create, JSON.parse(@listString)
        @list = AnnotationList.last()
        @listUID = @list.list_id.split('lists/').last
        get :show, {format: :json, id: @listUID}
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['label']).to eq("transcription layer 2 list 2")
      end

      it 'does not fail if within is nil' do
        listJSON = JSON.parse(@listString)
        listJSON['within'] = nil
        post :create, listJSON
        @list = AnnotationList.last()
        @listUID = @list.list_id.split('lists/').last
        get :show, {format: :json, id: @listUID}
        expect(response.status).to eq(200)
      end

    end

    context 'when Put is called' do
      describe 'Put annotationList json' do
        before(:each) do
          @listString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json", "label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/testLayer"]}'
          post :create, JSON.parse(@listString)
          @list = AnnotationList.last()
          @listJSON = JSON.parse(@listString)
          @listJSON['@id'] = @list.list_id
        end

        it 'does not change the record count' do
          @listJSON['label'] = 'label update'
          expect { put :update, @listJSON }.to change(AnnotationList, :count).by(0)
        end

        it 'returns a 200 response' do
          @listJSON['label'] = 'label update'
          put :update, @listJSON, :format => 'json'
          expect(response.status).to eq(200)
        end

        it 'updates the label field' do
          @listJSON['label'] = 'label update'
          put :update, @listJSON, :format => 'json'
          responseJSON = JSON.parse(response.body)
          expect(responseJSON['label']).to eq("label update")
        end

        it 'fails validation correctly' do
          @listJSON['label'] = nil
          put :update, @listJSON, :format => 'json'
          expect(response.status).to eq(422)
        end

        it 'does not fail if  if [within] is blank' do
          @listJSON['within'] = nil
          put :update, @listJSON, :format => 'json'
          expect(response.status).to eq(200)
        end

        it 'updates the layer_annotations map correctly'  do
          @listJSON['label'] = 'label update'
          put :update, @listJSON, :format => 'json'
          @layers = LayerListsMap.getLayersForList @list.list_id
          expect(@layers).to eq(@listJSON['within'])
        end

        it 'creates a version correctly' do
          @listJSON['label'] = 'label update'
          put :update, @listJSON, :format => 'json'
          @list = AnnotationList.last()
          @version = AnnoListLayerVersion.last()
          expect(@list.version).to eq(2)
          expect(@version.all_id).to eq(@list.list_id)
          expect(@version.all_type.downcase).to eq("sc:annotationlist")
          expect(@version.all_version).to eq(@list.version-1)
        end

      end
    end


    context 'when Delete is called' do
      describe 'Delete annotation' do
        before(:each) do
          @listString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json", "label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/testLayer"]}'
          post :create, JSON.parse(@listString)
          @list = AnnotationList.last()
          @listUID = @list.list_id.split('lists/').last
        end

        it 'returns a 201 ("created") response' do
          delete :destroy, format: :json, id: @listUID
          expect(response.status).to eq(204)
        end

        it 'decreases the list record count' do
          expect {delete :destroy, {format: :json, id: @listUID} }.to change(AnnotationList, :count).by(-1)
        end

        it 'deletes the list record' do
          delete :destroy, format: :json, id: @listUID
          expect(@listDeleted = AnnotationList.where(list_id: @list.list_id).first).to eq(nil)
        end

        it 'deletes the list_annotations map correctly' do
          delete :destroy, format: :json, id: @listUID
          @layers = LayerListsMap.getLayersForList @list.list_id
          expect(@layers).to eq([])
        end

        it 'creates a version correctly' do
          delete :destroy, format: :json, id: @listUID
          @version = AnnoListLayerVersion.last()
          expect(@list.version).to eq(1)
          expect(@version.all_id).to eq(@list.list_id)
          expect(@version.all_type.downcase).to eq("sc:annotationlist")
          expect(@version.all_version).to eq(@list.version)
        end
      end

    end
  end

  after(:all) do
    @annotationLayer.destroy!
  end
end




