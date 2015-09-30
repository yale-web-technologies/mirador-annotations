class User < ActiveRecord::Base

  has_and_belongs_to_many :groups, foreign_key: :group_id, primary_key: :group_id

  has_and_belongs_to_many :webacls
  #has_many :webacls, foreign_key: :group_id, primary_key: :group_id, through: :groups

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:cas]

  # Omniauth
  attr_accessible :provider,
                  :uid,
                  :password,
                  :email,
                  :encrypted_password,
                  :group_id

  def self.getUsersResourceIds user
    groupIds = Array.new
    user.groups.each do |group|
      groupIds.push(group.group_id)
    end

    resources = Webacl.where(:group_id => groupIds)
    #resources = user.webacls
    #resources = user.groups.webacls

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
   # @webaclExists = user.webacls.where(resource_id: resourceId, acl_mode: permissionType).first
    groupIds = Array.new
    user.groups.each do |group|
      groupIds.push(group.group_id)
    end
    resources = Webacl.where(:group_id => groupIds)
    @webaclExists = resources.where(resource_id: resourceId, acl_mode: permissionType).first
    !@webaclExists.nil?
  end
end
