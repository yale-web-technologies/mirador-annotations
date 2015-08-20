require 'rails_helper'

RSpec.describe AnnotationListController, type: :controller do
  context 'when Post is called' do
    describe 'POST annotation json' do
        before(:each) do
          @annoListString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json","motivation": "yale:transcribing","label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/6d46d0e9-c643-47c4-a1e1-985d674d5af7"]}'
        end

      it 'returns a 201 ("created") response' do
        post :create, JSON.parse(@annoListString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
        expect(response.status).to eq(201)
      end

      it 'creates a new List' do
        p (AnnotationList.count).to_s
        expect { post :create, JSON.parse(@annoListString) }.to change(AnnotationList, :count).by(1)
        p (AnnotationList.count).to_s
      end

      it 'creates an @id for the returned annotation' do
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

end

