module SessionManagement
  extend ActiveSupport::Concern

  included do
    before_action :validate_session, unless: :skip_session_validation?
  end

  private

  def create_user_session(user)
    session[:user_id] = user.id
    session[:last_activity] = Time.current.to_i
    session[:expires_at] = 1.hour.from_now.to_i
    
    # Store minimal user info in session for quick access
    session[:user_info] = {
      email: user.email,
      given_name: user.given_name,
      family_name: user.family_name
    }
  end

  def destroy_user_session
    reset_session
  end

  def validate_session
    unless valid_session?
      destroy_user_session
      handle_unauthorized
    end
  end

  def valid_session?
    return false if session[:user_id].blank? || 
                   session[:expires_at].blank? || 
                   session[:last_activity].blank?

    # Check if session has expired
    return false if Time.current.to_i > session[:expires_at]

    # Check if session has been inactive for too long (30 minutes)
    return false if Time.current.to_i - session[:last_activity] > 30.minutes

    # Update last activity timestamp
    session[:last_activity] = Time.current.to_i
    
    true
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def skip_session_validation?
    # Add paths that don't require session validation
    ['/auth/v1/control_plane_sso'].any? { |path| request.path.start_with?(path) }
  end
end 