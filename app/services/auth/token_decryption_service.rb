module Auth
  class TokenDecryptionService
    class DecryptionError < StandardError; end

    def initialize(encrypted_token)
      @encrypted_token = encrypted_token
    end

    def decrypt
      begin
        # First, decrypt the AES encrypted data
        decrypted_jwt = decrypt_aes
        
        # Then verify and decode the JWT
        verify_and_decode_jwt(decrypted_jwt)
      rescue StandardError => e
        Rails.logger.error("Token decryption failed: #{e.message}")
        raise DecryptionError, "Failed to decrypt token: #{e.message}"
      end
    end

    private

    def decrypt_aes
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.decrypt
      
      # Get the encryption key from key management service
      cipher.key = KeyManagementService.aes_encryption_key
      
      # Extract components from the encrypted token
      iv, auth_tag, encrypted_data = extract_token_components
      
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.auth_data = ''
      
      cipher.update(encrypted_data) + cipher.final
    end

    def verify_and_decode_jwt(token)
      # Decode and verify the JWT using the RSA private key
      JWT.decode(
        token,
        KeyManagementService.rsa_private_key,
        true,
        {
          algorithm: 'RS256',
          verify_iat: true,
          verify_aud: true,
          aud: ENV['JWT_AUDIENCE'] || 'your-rails-app',
          verify_iss: true,
          iss: ENV['JWT_ISSUER'] || 'cognito-sso-service'
        }
      ).first
    end

    def extract_token_components
      parts = @encrypted_token.split('.')
      raise DecryptionError, "Invalid token format" unless parts.length == 3
      
      [
        Base64.decode64(parts[0]), # IV
        Base64.decode64(parts[1]), # Auth Tag
        Base64.decode64(parts[2])  # Encrypted Data
      ]
    end
  end
end 