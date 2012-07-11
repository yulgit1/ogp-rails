class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  #include SulChrome::Controller

  #def layout_name
  # 'sul_chrome/application'
  #end

  helper_method :is_production?

  helper_method :current_user
  helper_method :destroy_user_session_path

  # used to determine if we should show beta message in UI
  def is_production?
    return true if Rails.env.production? and (!request.env["HTTP_HOST"].nil? and !request.env["HTTP_HOST"].include?("-test") and !request.env["HTTP_HOST"].include?("-dev") and !request.env["HTTP_HOST"].include?("localhost"))
  end

  def current_user
    'geostaff'
  end

  def destroy_user_session_path
    true
  end
  
  protect_from_forgery
end
