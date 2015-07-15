require 'rails_helper'

RSpec.describe AnnotationController, type: :controller do

  context "when post is called" do
    describe "POST annotation json" do

      before(:example)  do
        @annoString = '{
    "@id": "http://localhost:5000/annotations/3",
    "@type": "oa:Annotation",
    "motivation": "yale:transcribing",
    "resource":
{
    "@id": "http://localhost:5000/annotations/3",
    "@type": "cnt:ContentAsText",
	  "chars":  "annotation chars content",
    "format": "text/plain"
},
"annotatedBy":
    {
        "@id": "http://annotations.tenthousandrooms.yale.edu/user/5390bd85a42eedf8a4000001",
        "@type": "prov:Agent",
        "name": "Test User 3"
    },
    "on": "http://dms-data.stanford.edu/Walters/zw200wd8767/canvas/canvas-359#xywh=47,191,1036,1132"
}'
      end

      it "returns a 302 (redirect) response" do
        post :create, :annotation => @annoString
        expect(response.status).to eq(302)
      end

      it "assigns the version" do
        post :create, :annotation => @annoString
        @annotation = Annotation.last()
        expect(@annotation['version']).to eq (1)
      end

      it "assigns active" do
        post :create, :annotation => @annoString
        @annotation= Annotation.last()
        expect(@annotation['active']).to eq (true)
      end

      it "creates a new Annotation" do
        expect {post :create, :annotation => @annoString}.to change(Annotation, :count).by(1)
      end

    end
  end

end
