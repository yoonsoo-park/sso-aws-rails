module Auth
  module V1
    class ControlPlaneSsoController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:create]
      before_action :validate_params, only: [:create]
      
      def create
        encrypted_token = params[:token]
        state = params[:state]

        # Decrypt and validate the token
        token_service = TokenDecryptionService.new(encrypted_token)
        claims = token_service.decrypt

        # Synchronize user from claims
        sync_service = UserSynchronizationService.new(claims)
        user = sync_service.sync_user
        
        # TODO: Implement session management
        # create_user_session(user)

        render json: { 
          message: 'Authentication successful',
          user: {
            id: user.id,
            email: user.email,
            given_name: user.given_name,
            family_name: user.family_name
          }
        }, status: :ok
      rescue TokenDecryptionService::DecryptionError => e
        Rails.logger.error("Token decryption failed: #{e.message}")
        render json: { error: 'Invalid token' }, status: :unauthorized
      rescue UserSynchronizationService::SynchronizationError => e
        Rails.logger.error("User synchronization failed: #{e.message}")
        render json: { error: 'Failed to synchronize user' }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error("Authentication failed: #{e.message}")
        render json: { error: e.message }, status: :unauthorized
      end

      private

      def validate_params
        unless params[:token].present? && params[:state].present?
          raise ArgumentError, 'Missing required parameters: token and state'
        end
      end

      # TODO: Implement these methods
      # def find_or_create_user(claims)
      # end

      # def create_user_session(user)
      # end
    end
  end
end 