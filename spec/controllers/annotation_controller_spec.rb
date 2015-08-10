require 'rails_helper'

RSpec.describe AnnotationController, :type => :controller do

  context 'when post is called' do
    describe 'POST annotation json' do

      before(:all) do
        @annoString = {
            '@type' => 'oa:Annotation',
            'motivation' => 'yale:transcribing',
            'resource' =>
                {
                    '@type' => 'cnt:ContentAsText',
                    'chars' => 'annotation chars content',
                    'format' => 'text/plain'
                },
            'on' => 'http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1132'
        }

        # for JSON content type:
        @annoString[:format] = 'json'
      end

      it 'returns a 302 (redirect) response' do
        post :create, @annoString
        expect(response.status).to eq(201)
      end

      it 'creates a new Annotation' do
        expect { post :create,  @annoString }.to change(Annotation, :count).by(1)
      end

      it 'creates an @id for the returned annotation' do
        post :create, @annoString
        expect(response.status).to eq(201)
        json = JSON.parse(response.body)
        expect(json['@id']).to be_truthy
      end

      it 'assigns the version' do
        post :create, @annoString
        @annotation = Annotation.last()
        expect(@annotation['version']).to eq (1)
      end

      it 'assigns active' do
        post :create, @annoString
        @annotation= Annotation.last()
        expect(@annotation['active']).to eq (true)
      end

    end
  end

end
