class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #include Authentication

  #protect_from_forgery with: :exception

  #before_action :authenticate_user!

  #def get_user
  #  user = nil
  #  if user_signed_in?
  #    user = current_user
  #  end
  #  user
  #end
end
