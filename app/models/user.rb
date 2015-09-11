class User < ActiveRecord::Base

  has_one :group, foreign_key: :group_id, primary_key: :group_id
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id, through: :group

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  #devise :database_authenticatable, :registerable,
  #       :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:cas]

  # Omniauth
  attr_accessible :provider,
                  :uid,
                  :name,
                  :email,
                  :encrypted_password,
                  :group_id

  def self.getUsersResourceIds uid
    @user=User.find_by(uid:uid )
     resourceIds = Array.new
    resources = @user.webacls
    resources.each do |resource|
      resourceIds.push(resource.resource_id)
      #p "resource = #{resource.resource_id}   acl_mode: #{resource.acl_mode}    group_id: #{resource.group_id}"
    end
    resourceIds
  end

  def self.canUserAccess uid, resourceId
    userResources = getUsersResourceIds uid
    userResources.include? resourceId
  end

  def hasPermission user, resourceId, permissionType
    # pre-Devise implementation; am temporarily passing the @user for testing
    @user = user
    p "#hasPermission: @user.uid = #{@user.uid}  @user.group_id = #{@user.group_id}"
    hasPermission = false
    @webacl = @user.webacls.find_by(resource_id: resourceId, acl_mode: permissionType)
    hasPermission = true if !@webacl.nil?
    hasPermission
  end
end
