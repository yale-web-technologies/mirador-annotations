require 'rails_helper'
require './spec/support/anno_auth_helper'

RSpec.configure do |c|
  c.include AnnoAuthHelper
end

RSpec.describe AnnoAuthValidator do

  context 'when authorize is called' do
    describe 'validate canvas and user' do
      before(:each) do
        Rails.application.secrets.jwt_password = 'abc123'
        Rails.application.config.jwt_canvas_verification_url = 'http://testserver.com'
        allow(JWT).to receive(:decode).and_return([{"group_id" => "10", "user_id" => "100"}])
      end

      it 'check valid JWT' do
        stub_anno_auth("10", "true", /testserver.com/)
        authorize = described_class.authorize("Bearer someencryptedtoken", "http://canvas.testserver.com/canvas/12345")
        expect(authorize).to be_truthy
      end

      it 'check non-matching group id' do
        stub_anno_auth("11", "true", /testserver.com/)
        authorize = described_class.authorize("Bearer someencryptedtoken", "http://canvas.testserver.com/canvas/12345")
        expect(authorize).to be_falsey
      end

      it 'error decoding JWT' do
        stub_anno_auth("10", "false", /testserver.com/)
        authorize = described_class.authorize("Bearer someencryptedtoken", "http://canvas.testserver.com/canvas/12345")
        expect(authorize).to be_falsey
      end

      it 'error with remote server' do
        stub_anno_auth(nil, nil, /testserver.com/)
        authorize = described_class.authorize("Bearer someencryptedtoken", "http://canvas.testserver.com/canvas/12345")
        expect(authorize).to be_falsey
      end
    end
  end
end