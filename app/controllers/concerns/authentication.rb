module Authentication
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_user!
    helper_method :current_user, :logged_in?
  end
  
  def current_user
    @current_user ||= begin
      if session[:user_data]
        session[:user_data]
      elsif request.headers['Authorization'].present?
        token = request.headers['Authorization'].split(' ').last
        user_data = AuthApiService.validate_token(token)
        session[:user_data] = user_data if user_data
        user_data
      end
    end
  end
  
  def logged_in?
    current_user.present?
  end
  
  def authenticate_user!
    unless logged_in?
      respond_to do |format|
        format.html { redirect_to login_path, alert: 'Please log in to continue' }
        format.json { render json: { error: 'Unauthorized' }, status: :unauthorized }
      end
    end
  end
  
  def require_same_user_or_admin!(external_id)
    unless current_user && (current_user['external_id'] == external_id || current_user['role'] == 'admin')
      respond_to do |format|
        format.html { redirect_to posts_path, alert: 'You are not authorized to perform this action' }
        format.json { render json: { error: 'Forbidden' }, status: :forbidden }
      end
    end
  end
end