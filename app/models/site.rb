class Site < ActiveRecord::Base

  has_many :groups

  def findGroupforSiteRole role
    @group = Group.where(site_id:site_id, role:role).first
  end
end
