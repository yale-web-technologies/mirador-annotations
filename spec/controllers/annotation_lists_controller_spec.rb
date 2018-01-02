require 'rails_helper'

RSpec.describe AnnotationListsController, type: :controller do

  before(:all) do
    layer = {
      '@id' => 'http://localhost:5000/layers/testLayer',
      '@type' => 'sc:Layer',
      '@context' => 'http://iiif.io/api/presentation/2/context.json',
      'label' => 'Layer 2'
    }
    @annotationLayer = AnnotationLayer.create_from_iiif(layer)
  end

  context 'when Get is called' do
    describe 'GET annotation json' do
      before(:each) do
        AnnotationList.delete_all
        AnnotationLayer.delete_all
        Canvas.delete_all

        layer = AnnotationLayer.create({
          layer_id: '/layer/1',
          label: 'Layer 1'
        })

        canvas = Canvas.create({
          iiif_canvas_id: '/cavnas/1',
          label: 'Canvas 1'
        })

        @list = AnnotationList.new({
          list_id: "#{Rails.application.config.hostUrl}/lists/1987",
          label: 'Canvas 1 Layer 1 List 1'
        })
        @list.canvas = canvas
        @list.save!
        @list.annotation_layers << layer
      end

      it 'returns a 200 response' do
        get_to_show('1987')
        expect(response.status).to eq(200)
      end

      it 'retrieves label correctly' do
        get_to_show('1987')
        responseJSON = JSON.parse(response.body)
        expect(responseJSON['label']).to eq('Canvas 1 Layer 1 List 1')
      end
    end
  end

  after(:all) do
    @annotationLayer.destroy!
  end

  def get_to_show(list_id)
    get :show, params: { id: list_id, format: 'json' }
  end
end




