class Webacl < ActiveRecord::Base
  belongs_to :group

  def self.getAclsByResource resource_id
    @webAcls = Webacl.where(resource_id:resource_id)
  end

  def self.getAclsByGroup group_id
    @webAcls = Webacl.where(group_id:group_id)
  end

  def self.createWebacl( aclHash ) #{ resource_id, group, permission }
      Webacl.create(JSON.parse(aclHash))
  end
end
