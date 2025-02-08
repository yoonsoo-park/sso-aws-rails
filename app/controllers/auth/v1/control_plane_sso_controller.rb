module Auth
  module V1
    class ControlPlaneSsoController < ApplicationController
      # Skip CSRF for API requests but enforce it for browser requests
      skip_before_action :verify_authenticity_token, if: :api_request?
      before_action :validate_params, only: [:create]
      
      def create
        # Handle both GET and POST parameters
        encrypted_token = params[:token]
        state = params[:state]

        # Debug log the received token
        Rails.logger.info "Received encrypted token for SSO authentication"
        
        # Decrypt and validate the token
        token_service = TokenDecryptionService.new(encrypted_token)
        claims = token_service.decrypt
        
        # Debug log the decrypted claims
        Rails.logger.info "Successfully decrypted token. Claims: #{claims.inspect}"

        # Synchronize user from claims
        sync_service = UserSynchronizationService.new(claims)
        user = sync_service.sync_user
        
        # Debug log the user information
        Rails.logger.info "User authenticated successfully: ID=#{user.id}, Email=#{user.email}"
        
        # Create user session
        create_user_session(user)

        # If it's a GET request, redirect to a success page
        if request.get?
          redirect_to '/auth/success', notice: 'Authentication successful'
        else
          # For POST requests, return JSON response
          render json: { 
            message: 'Authentication successful',
            user: {
              id: user.id,
              email: user.email,
              given_name: user.given_name,
              family_name: user.family_name
            },
            session: {
              expires_at: session[:expires_at]
            }
          }, status: :ok
        end
      rescue TokenDecryptionService::DecryptionError => e
        Rails.logger.error("Token decryption failed: #{e.message}")
        handle_error('Invalid token', :unauthorized)
      rescue UserSynchronizationService::SynchronizationError => e
        Rails.logger.error("User synchronization failed: #{e.message}")
        handle_error('Failed to synchronize user', :unprocessable_entity)
      rescue StandardError => e
        Rails.logger.error("Authentication failed: #{e.message}")
        handle_error(e.message, :unauthorized)
      end

      def destroy
        destroy_user_session
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      private

      def validate_params
        unless params[:token].present? && params[:state].present?
          raise ArgumentError, 'Missing required parameters: token and state'
        end
      end

      def handle_error(message, status)
        if request.get?
          redirect_to '/auth/error', alert: message
        else
          render json: { error: message }, status: status
        end
      end

      def api_request?
        request.format.json? || request.headers['Accept']&.include?('application/json')
      end

      # TODO: Implement these methods
      # def find_or_create_user(claims)
      # end

      # def create_user_session(user)
      # end
    end
  end
end 