class Webacl < ActiveRecord::Base
  attr_accessible :resource_id,
                  :acl_mode,
                  :group_id

  has_and_belongs_to_many :groups, foreign_key: :group_id, primary_key: :group_id, :validate =>false, :dependent =>:delete_all
  #has_many :users, foreign_key: :group_id, primary_key: :group_id, through: :group, :validate =>false, :dependent =>:restrict_with_error
  has_and_belongs_to_many :users, foreign_key: :group_id, primary_key: :group_id, through: :group, :validate =>false, :dependent =>:delete_all


  def self.getAclsByResource resource_id
    @webAcls = Webacl.where(resource_id:resource_id)
  end

  def self.getAclsByGroup group_id
    @webAcls = Webacl.where(group_id:group_id)
  end

end
