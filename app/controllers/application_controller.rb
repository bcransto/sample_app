class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_user, :logged_in?
  
  def current_user
    @current_user ||= session[:user_data] if session[:user_data]
  end
  
  def logged_in?
    current_user.present?
  end
end
