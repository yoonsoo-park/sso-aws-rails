class ApplicationController < ActionController::API
  include SessionManagement
  
  # Enable cookies for API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include ActionController::MimeResponds

  # Enable CSRF protection
  protect_from_forgery with: :exception

  private

  def handle_unauthorized
    respond_to do |format|
      format.html { redirect_to '/auth/error', alert: 'Session expired' }
      format.json { render json: { error: 'Session expired' }, status: :unauthorized }
    end
  end
end
