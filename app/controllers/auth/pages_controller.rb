module Auth
  class PagesController < ActionController::Base
    # Skip session validation for these pages
    skip_before_action :validate_session, raise: false
    
    def success
      render 'auth/success'
    end

    def error
      render 'auth/error'
    end
  end
end 