class User < ActiveRecord::Base

  #has_one :group, foreign_key: :group_id, primary_key: :group_id
  has_many :group, foreign_key: :group_id, primary_key: :group_id, :validate =>false, :dependent =>:delete_all
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id, through: :group, :validate =>false, :dependent =>:delete_all

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

  def self.getUsersResourceIds uid
    @user=User.find_by(uid:uid )
    resourceIds = Array.new

    resources = @user.webacls
    resources.each do |resource|
      resourceIds.push(resource.resource_id)
      #p "uid: #{uid} resource = #{resource.resource_id}   acl_mode: #{resource.acl_mode}    group_id: #{resource.group_id}"
    end

    #groups = @user.groups
    #groups.each do |group|
    #  p "group_id: #{group_id}"
    #end

    resourceIds
  end

  def self.canUserAccess uid, resourceId
    userResources = getUsersResourceIds uid
    userResources.include? resourceId
  end

  # this is now in abiity.rb
  def hasPermission user, resourceId, permissionType
    @webaclExists = user.webacls.where(resource_id: resourceId, acl_mode: permissionType).first
    !@webaclExists.nil?
  end
end
