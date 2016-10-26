require "json"

class AuthnController < ApplicationController

=begin
xx Success
200	OK	:ok
201	Created	:created
202	Accepted	:accepted
203	Non-Authoritative Information	:non_authoritative_information
204	No Content	:no_content
205	Reset Content	:reset_content
206	Partial Content	:partial_content
207	Multi-Status	:multi_status
226	IM Used	:im_used
=end

  def userLogin
    # get params
    uid = params['user_id']
    p "user logging in: #{uid}"
    bearerToken = params['ticket']
    # below optional
    expiry = params['expiry']
    email = params['email']
    provider = params['provider']  # or just fill in with "Drupal" ?

    # lookup user; create if not found
    #@userFound = User.where(:provider => auth.provider, :uid => auth.uid).first
    @userFound = User.where(:uid => uid).first

    if @userFound.nil?
      @user = createUser
    else
      p "user found provider: #{@userFound.provider}"
      @user = @userFound
    end

    # now we have the user record whether it already existed or not, now update it with token and expiry
    #render :json => { :uid => "#{uid} logged in" },
    #       :status => :ok
    respond_to do |format|
      if @user.update_attributes(
          :bearer_token => params['ticket'],
          #:expiry => Time.now + 7.days
      )
        format.html { redirect_to @annotation, notice: 'Annotation was successfully updated.' }
        format.json { render json: @annotation.to_iiif, status: 200, content_type: "application/json"}
      else
        format.html { render action: "edit" }
        format.json { render json: @annotation.errors, status: :unprocessable_entity, content_type: "application/json" }
      end
    end

  end

  def newGroup

  end

  def userRegisteredForGroup

  end

  def createUser
    p "in createUser: params[user_id] = #{params['user_id']}"

    if !params['provider'].nil?
      provider = params['provider']
    else
      provider = "ExternalUserToken"
    end

    @user = User.create(
      provider: provider,
      uid: params['user_id'],
      email: Devise.friendly_token[0,20],
      password: params['user_id']
      )

  end

  def deleteUser

  end


end