class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  prepend_before_filter { request.env["devise.skip_timeout"] = true }

    def cas
       def auth
        request.env['omniauth.auth']
       end
      @user = User.where(:provider => auth.provider, :uid => auth.uid).first
      # puts 'User first name = ' + @user.name
      #if @user.nil?
      #  @user = User.create(
      #      provider: auth.provider,
      #      uid: auth.uid,
      #     email: auth.uid+ "@yale.edu",
      #     password: Devise.friendly_token[0,20]
      #  )
      # end

       if !@user.nil?
         sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
         set_flash_message(:notice, :success, :kind => "CAS") if is_navigational_format?
       else
         p 'no such user!'
         redirect_to new_user_registration_url
       end

    end
end