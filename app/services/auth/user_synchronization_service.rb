module Auth
  class UserSynchronizationService
    class SynchronizationError < StandardError; end

    def initialize(claims)
      @claims = claims
    end

    def sync_user
      ActiveRecord::Base.transaction do
        user = find_or_initialize_user
        update_user_attributes(user)
        user
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to synchronize user: #{e.message}")
      raise SynchronizationError, "Failed to synchronize user: #{e.message}"
    end

    private

    def find_or_initialize_user
      User.find_or_initialize_by(cognito_sub: @claims['sub'])
    end

    def update_user_attributes(user)
      user.assign_attributes(
        email: @claims['email'],
        given_name: @claims['given_name'],
        family_name: @claims['family_name'],
        last_sign_in_at: Time.current
      )
      
      # Add any additional attributes from claims if needed
      user.save!
    end
  end
end 