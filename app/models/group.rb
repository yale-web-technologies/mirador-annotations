class Group < ActiveRecord::Base

  belongs_to :site
  has_and_belongs_to_many :users
  has_and_belongs_to_many :annotation_layers
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id

  #serialize :permissions

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
