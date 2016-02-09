class User < ActiveRecord::Base

  has_and_belongs_to_many :groups

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable #, :registerable,
         :recoverable #, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:cas]

  # Omniauth
  attr_accessible :provider,
                  :uid,
                  :password,
                  :email,
                  :encrypted_password,
                  :tgToken,
                  :bearerToken

  def self.getUsersResourceIds user
    groupIds = Array.new
    user.groups.each do |group|
      groupIds.push(group.group_id)
    end
    resources = Webacl.where(:group_id => groupIds)
    resourceIds = Array.new
    resources.each do |resource|
      resourceIds.push(resource.resource_id)
    end
    resourceIds
  end

  def self.canUserAccess user, resourceId
    userResources = getUsersResourceIds user
    userResources.include? resourceId
  end

  # this is now also in abiity.rb
  def hasPermission user, resourceId, permissionType
    # first allow if resource has a webacls assigned to group "pubic"
    @webaclExists = Webacl.where(group_id: "public", resource_id: resourceId, acl_mode: permissionType).first
    if @webaclExists.nil?
      groupIds = Array.new
      user.groups.each do |group|
        groupIds.push(group.group_id)
      end
      resources = Webacl.where(:group_id => groupIds)
      @webaclExists = resources.where(resource_id: resourceId, acl_mode: permissionType).first
    end
    !@webaclExists.nil?
  end

end
