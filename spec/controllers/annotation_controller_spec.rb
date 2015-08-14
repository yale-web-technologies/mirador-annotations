require 'rails_helper'

RSpec.describe AnnotationController, :type => :controller do

  context 'when post is called' do
    describe 'POST annotation json' do

      before(:all) do
        @annoString ='{"@type": "oa:annotation",
                      "motivation": "yale:transcribing",
                      "within":["http://localhost:5000/lists/e7ceec6a-af59-4191-a74c-39a7acfe90ce"],
                      "label":"transcription1 list 1 annotation 1",
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

    end
  end

end
