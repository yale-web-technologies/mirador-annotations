class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #include Authentication

  #protect_from_forgery with: :exception
  #before_action :authenticate_user!

  def login
    authenticate_user!
    respond_to do |format|
      format.html { redirect_to :root }
    end
  end

  def get_access_token
    #lines below if using jsonp
    #callback = params[:callback]
    #tgToken = params[:tgToken]
    #if (tgToken==current_user.tgToken)
    #    accessTokenCallback = callback + "({'accessToken':'#{current_user.bearerToken}','tokenType':'Bearer','expiresIn':3600})"
    #else
    #  accessTokenCallback = callback + '({"accessToken":"TOKEN_MATCH_FAILED","tokenType":"Bearer","expiresIn":3600})'
    #end
    #p "accessTokenCallback = #{accessTokenCallback}"

    p "in get_access_token: user_signed_in? = " + user_signed_in?.to_s
    tgToken = request.headers["tgToken"]
    p "get_access_token: tgToken = #{tgToken}"

    if (!user_signed_in?)         # user woud be signed in if this was a jsonp call, with a cookie tying it to a user session
      signInUserByTgToken(tgToken)
    end

    # now get the token as field from this user.
    if (tgToken==current_user.tgToken)
      accessTokenCallback = '{"accessToken":"' +
                            current_user.bearerToken +
                          '","tokenType":"Bearer","expiresIn":3600}'
    else
      accessTokenCallback ='{"accessToken":"TOKEN_MATCH_FAILED","tokenType":"Bearer"}'
    end

    respond_to do |format|
        format.json { render json: accessTokenCallback.to_json, status: 200}
    end
  end

  def signInUserByBearerToken bearerToken
    @user = User.where(:bearerToken => bearerToken).first
    if (!@user.nil?)
        #p "about to sign in user #{@user.uid} based on bearerToken"
        sign_in(@user)
        #p "just signed in user #{@user.uid} based on bearerToken"
        #p "and current_user = #{current_user.uid}"
    end

  end

  def signInUserByTgToken tgToken
    @user = User.where(:tgToken => tgToken).first
    #p "about to sign in user #{@user.uid} based on tgToken"
    sign_in(@user)
    #p "just signed in user #{@user.uid} based on tgToken"
    #p "and current_user = #{current_user.uid}"
  end

  end
