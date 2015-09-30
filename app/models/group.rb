class Group < ActiveRecord::Base

  has_and_belongs_to_many :users, foreign_key: :group_id, primary_key: :group_id

  #has_and_belongs_to_many :webacls, foreign_key: :group_id, primary_key: :group_id
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id

  attr_accessible :group_id,
                  :group_description


  def self.getGroupsResourceIds group
    #groupIds = Array.new
    #user.groups.each do |group|
    #  groupIds.push(group.group_id)
    #end

    p "group.group_id = #{group.group_id}"
    #resources = Webacl.where(group_id: group.group_id)
    resources = group.webacls

    resourceIds = Array.new
    resources.each do |resource|
      p "resource group_id: #{resource.group_id}"
      resourceIds.push(resource.resource_id)
    end
    resourceIds
  end

  def self.getGroupsUserIds group
    users = group.users
    userIds = Array.new
    users.each do |user|
      p "user id = #{user.uid}"
      userIds.push(user.uid)
    end
  end

  attr_accessible :group_id, :group_description
end
