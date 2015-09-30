class Group < ActiveRecord::Base

  has_and_belongs_to_many :users
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id

  attr_accessible :group_id,
                  :group_description


  def self.getGroupsResourceIds group
    resources = group.webacls
    resourceIds = Array.new
    resources.each do |resource|
      resourceIds.push(resource.resource_id)
    end
    resourceIds
  end

  def self.getGroupsUserIds group
    users = group.users
    userIds = Array.new
    users.each do |user|
      userIds.push(user.uid)
    end
  end

end
