class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :cognito_sub, presence: true, uniqueness: true
  
  # Attributes expected from Cognito JWT claims:
  # - email
  # - cognito_sub (sub claim)
  # - given_name
  # - family_name
  
  def self.from_jwt_claims(claims)
    user = find_or_initialize_by(cognito_sub: claims['sub'])
    
    user.assign_attributes(
      email: claims['email'],
      given_name: claims['given_name'],
      family_name: claims['family_name'],
      last_sign_in_at: Time.current
    )
    
    # Update any additional attributes from claims if needed
    user.save!
    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create/update user from claims: #{e.message}")
    raise
  end
end 