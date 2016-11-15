include AclCreator
require "json"
require "csv"
require 'date'

class AuthnController < ApplicationController

  def userLogin
    # get params
    uid = params['user_id']
    p "user logging in: #{uid}"
    bearerToken = params['ticket']
    p "bearer_token = #{bearerToken}"
    # below optional
    expiry = params['expiry']
    email = params['email']
    provider = params['provider']  # or just fill in with "Drupal" ?

    # lookup user; create if not found
    #@userFound = User.where(:provider => auth.provider, :uid => auth.uid).first
    if !uid.nil?
      @userFound = User.where(:uid => uid).first
      if @userFound.nil? && !uid.nil?
        @user = createUser
      else
        p "user found provider: #{@userFound.provider}"
        @user = @userFound
      end
    end

    # now we have the user record whether it already existed or not, now update it with token and expiry
    #render :json => { :uid => "#{uid} logged in" },
    #       :status => :ok
    userId = "nil" if uid.nil?
    respond_to do |format|
      succeeded = '"login":"succeeded"'.to_json
      failed = '"login":"failed"'.to_json
      if !uid.nil?
        if @user.update_attributes(
            :bearerToken => bearerToken,
            #:expiry => Time.now + 7.days
        )
          success = "#{userId} logged in"
          format.html { render json: succeeded, status: 200, content_type: "application/json" }
          format.json { render json: succeeded, status: 200, content_type: "application/json"}
        else
          format.html { render json: failed.to_json, status: :unprocessable_entity, content_type: "application/json" }
          format.json { render json: failed.to_json, status: :unprocessable_entity, content_type: "application/json" }
        end
      else
        format.html { render json: failed.to_json, status: :unprocessable_entity, content_type: "application/json" }
        format.json { render json: failed.to_jsond, status: :unprocessable_entity, content_type: "application/json" }
      end
    end
  end


  def createUser
    #create user, user_group record, group record if needed and create public webacl
    p "in createUser: params[user_id] = #{params['user_id']}"
    p "in createUser: params[group_id] = #{params['group_id']}"

    if !params['provider'].nil?
      provider = params['provider']
    else
      provider = "ExternalUserTokenProvider"
    end

    user = User.create(
      provider: provider,
      uid: params['user_id'],
      email: params['user_id'],
      password: params['user_id']
      )

    # now check group exists; create if needed
    group = Group.where(:group_id => params['group_id'])
    p "checked for group: result count = #{group.count}"
    p "checked for group: @group.nil? = #{group.nil?.to_s}"
    if group.count == 0
      p "creating group for #{params['group_id']}"
      group = Group.create(
        group_id: params['group_id'],
        group_description: "test",
        roles: "tbd",
        permissions: "tbd"
      )
      p "group #{params['group_id']} created"
    end

    # now push user to groups via has-and-belongs-to-many relationship which uses the groups_users table
    user.groups << group
    p "group #{group.group_id} pushed to user.groups"

    # now create public webacl for this user and group for read_only (check)
    acl = {'resource_id' => 'general resource', 'acl_mode' => 'read', 'group_id' => group.group_id}
    webAcl = Webacl.create(acl)
    p "webacl: #{webAcl} created"

    user
  end

  def deleteUser

  end

  def newGroup

  end

  def userRegisteredForGroup

  end

end