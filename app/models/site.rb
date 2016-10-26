class Site < ActiveRecord::Base

  has_many :groups

  attr_accessible :site_id,
                  :site_title,
                  :site_description

  def findGroupforSiteRole role
    @group = Group.where(site_id:site_id, role:role).first
  end
end
