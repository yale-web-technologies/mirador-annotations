require 'webmock/rspec'

module AnnoAuthHelper
  def stub_anno_auth(group_id, has_access, server)
    body = if group_id.nil? && has_access.nil? 
            [{}]
          else
            [{"group_id": group_id, "has_access": has_access}]
          end
    stub_request(:get, server).
      to_return(status: 200, body: body.to_json)   
  end

  def set_anno_auth_token(auth_header)
    @request.headers['Authorization'] =   "Bearer #{auth_header}"
  end
end