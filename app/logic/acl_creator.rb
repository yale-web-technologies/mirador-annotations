module AclCreator

  def create_annotation_acls_via_parent_lists resource_id
    lists = Array.new
    lists = ListAnnotationsMap.getListsForAnnotation resource_id

    lists.each do |list|
      acls = Webacl.getAclsByResource list
        acls.each do |acl|
          rewriteParentAclForNewResource resource_id, acl
        end
    end
  end

  def create_list_acls_via_parent_layers resource_id
    lists = Array.new
    lists = getListsForAnnotations resourceId # this is in annotation_lists_map.rb
    lists.each do |list|
      acls = Webacl.getAclsByResource resource_id
      acls.each do |acl|
        rewriteParentAclForNewResource resource_id, acl
      end
    end
  end

  def rewriteParentAclForNewResource resource_id, acl
    new_acl = '{"resource_id":"' + resource_id + '","acl_mode":"' + acl.acl_mode + '","group_id":"' + acl.group_id + '"}'
    p 'acl = ' + new_acl.to_s
    Webacl.create(JSON.parse(new_acl))
  end

end


