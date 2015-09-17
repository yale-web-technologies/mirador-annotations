class WebaclController < ApplicationController
  # POST /layer
  # POST /layer.json
  def create
    @webAclIn = JSON.parse(params.to_json)
    @webAclHash = Hash.new
    @webAclHash['resource_id'] = @webaclIn['resource_id']
    @webAclHash['acl_mode'] = @layerIn['acl_mode']
    @webAclHash['group_id'] = @layerIn['group_id']

    @webAcl = Webacl .new(@webAclHash)

    #authorize! :create, @annotation_layer
    respond_to do |format|
      if @webAcl.save
        format.html { redirect_to @annotation_layer, notice: 'Web ACL was successfully created.' }
        format.json { render json: @web_acl.to_iiif, status: :created, location: @web_acl }
      else
        format.html { render action: "new" }
        format.json { render json: @aweb_acl.errors, status: :unprocessable_entity }
      end
    end
  end
end
