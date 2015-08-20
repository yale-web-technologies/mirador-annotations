require 'rails_helper'

RSpec.describe AnnotationController, :type => :controller do

  context 'when Post is called' do
    describe 'POST annotation json' do

      before(:all) do
        #@controller = AnnotationListController
        #@annoListString ='{"@type": "sc:AnnotationList","@context": "http://iiif.io/api/presentation/2/context.json","motivation": "yale:transcribing","label":"transcription layer 2 list 2","within":["http://localhost:5000/layers/6d46d0e9-c643-47c4-a1e1-985d674d5af7"]}'
        #post :create, JSON.parse(@annoListString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
        #@list = AnnotationList.last()
        #@listId = @annotation.list_id
        #@controller = AnnotationController

        #@controller = AnnotationController
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/e7ceec6a-af59-4191-a74c-39a7acfe90ce"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
      end

      it 'returns a 201 ("created") response' do
        post :create, JSON.parse(@annoString), :format => 'json', :Content_Type => 'application/json', :Accept => 'application/json'
        expect(response.status).to eq(201)
      end

      it 'creates a new Annotation' do
        expect { post :create, JSON.parse(@annoString) }.to change(Annotation, :count).by(1)
      end

      it 'creates an @id for the returned annotation' do
        post :create, JSON.parse(@annoString)
        expect(response.status).to eq(201)
        json = JSON.parse(response.body)
        expect(json['@id']).to be_truthy
      end

      it 'assigns the version' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        expect(@annotation['version']).to eq (1)
      end

      it 'fails validation if motivation is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['motivation'] = nil
        post :create, annoJSON
        expect(response.status).to eq(422)
      end

      it 'does not fail validation if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        expect(response.status).to eq(201)
      end

      it 'updates the map if within is not nil' do
        annoJSON = JSON.parse(@annoString)
        post :create, annoJSON
        json = JSON.parse(response.body)
        lists = ListAnnotationsMap.getListsForAnnotation json['@id']
        expect(lists).not_to eq(nil)
        expect(lists).to eq(annoJSON['within'])
      end
    end
  end

  context 'when Get is called' do
    describe 'GET annotation json' do
      before(:each) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/e7ceec6a-af59-4191-a74c-39a7acfe90ce"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        end

      it 'returns a 200 response' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end

      it 'retrieves motivation correctly' do
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transcribing")
      end

      it 'does not fail if within is nil' do
        annoJSON = JSON.parse(@annoString)
        annoJSON['within'] = nil
        post :create, annoJSON
        @annotation = Annotation.last()
        annoUID = @annotation.annotation_id.split('annotations/').last
        get :show, {format: :json, id: annoUID}
        expect(response.status).to eq(200)
      end
    end
  end

  context 'when Put is called' do
    describe 'Put annotation json' do
      before(:each) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/e7ceec6a-af59-4191-a74c-39a7acfe90ce","http://localhost:5000/lists/a750962a-f361-46d2-817f-038d085460aa"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
        @annoJSON = JSON.parse(@annoString)
        @annoJSON['@id'] = @annotation.annotation_id
      end

      it 'does not change the record count' do

        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        expect { put :update, @annoJSON }.to change(Annotation, :count).by(0)
      end

      it 'returns a 200 response' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(200)
      end

      it 'updates the motivation field' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['motivation']).to eq("yale:transliterating")
      end

      it 'fails validation correctly' do
        @annoJSON['motivation'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(422)
      end

      it 'does not fail if  if [within] is blank' do
        @annoJSON['within'] = nil
        put :update, @annoJSON, :format => 'json'
        expect(response.status).to eq(200)
      end

      it 'updates the list_annotations map correctly'  do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq(@annoJSON['within'])
      end

      it 'creates a version correctly' do
        @annoJSON['motivation'] = 'yale:transliterating'
        put :update, @annoJSON, :format => 'json'
        @annotation = Annotation.last()
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(2)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version-1)
      end

    end
  end

  context 'when Delete is called' do
    describe 'Delete annotation' do
      before(:each) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/e7ceec6a-af59-4191-a74c-39a7acfe90ce","http://localhost:5000/lists/a750962a-f361-46d2-817f-038d085460aa"],
                      "resource":{"@type":"cnt:ContentAsText","chars":"transcription1 list 1 annotation 1 **","format":"text/plain"},
                      "annotatedBy":{"@id":"http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001","@type":"prov:Agent","name":"Test User 8"},
                      "on":"http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1140"}'
        post :create, JSON.parse(@annoString)
        @annotation = Annotation.last()
      end

      it 'returns a 201 ("created") response' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        expect(response.status).to eq(204)
      end

      it 'decreases the Annotation record count' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        expect {delete :destroy, {format: :json, id: annoUID} }.to change(Annotation, :count).by(-1)
      end

      it 'deletes the Annotation record' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        expect(@annotationDeleted = Annotation.where(annotation_id: @annotation.annotation_id).first).to eq(nil)
      end

      it 'deletes the list_annotations map correctly' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        @lists = ListAnnotationsMap.getListsForAnnotation @annotation.annotation_id
        expect(@lists).to eq([])
      end

      it 'creates a version correctly' do
        annoUID = @annotation.annotation_id.split('annotations/').last
        delete :destroy, format: :json, id: annoUID
        @version = AnnoListLayerVersion.last()
        expect(@annotation.version).to eq(1)
        expect(@version.all_id).to eq(@annotation.annotation_id)
        expect(@version.all_type).to eq("oa:annotation")
        expect(@version.all_version).to eq(@annotation.version)
      end
    end
  end
end