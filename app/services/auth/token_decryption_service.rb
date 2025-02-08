module Auth
  class TokenDecryptionService
    class DecryptionError < StandardError; end

    def initialize(encrypted_token)
      @encrypted_token = encrypted_token
    end

    def decrypt
      begin
        Rails.logger.debug "Starting token decryption process"
        Rails.logger.debug "Token format: #{debug_token_format(@encrypted_token)}"
        
        # First, decrypt the AES encrypted data
        decrypted_jwt = decrypt_aes
        Rails.logger.debug "Successfully decrypted AES data"
        
        # Then verify and decode the JWT
        verify_and_decode_jwt(decrypted_jwt)
      rescue StandardError => e
        Rails.logger.error("Token decryption failed: #{e.message}")
        Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
        raise DecryptionError, "Failed to decrypt token: #{e.message}"
      end
    end

    private

    def decrypt_aes
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.decrypt
      
      # Get the encryption key from key management service
      key = KeyManagementService.aes_encryption_key
      Rails.logger.debug "AES key loaded successfully (length: #{key.bytesize} bytes)"
      Rails.logger.debug "Key (hex): #{key.unpack1('H*')}"
      cipher.key = key
      
      # Extract components from the encrypted token
      iv, auth_tag, encrypted_data = extract_token_components
      Rails.logger.debug "Token components extracted:"
      Rails.logger.debug " - IV (hex): #{iv.unpack1('H*')} (#{iv.length} bytes)"
      Rails.logger.debug " - Auth Tag (hex): #{auth_tag.unpack1('H*')} (#{auth_tag.length} bytes)"
      Rails.logger.debug " - Encrypted Data length: #{encrypted_data.length} bytes"
      
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.auth_data = ""  # Empty string as auth_data, matching the TypeScript implementation
      
      begin
        # Decrypt the data in chunks to match the TypeScript implementation
        decrypted = cipher.update(encrypted_data)
        decrypted << cipher.final
        
        # Convert to UTF-8 string, matching the TypeScript implementation
        decrypted.force_encoding('UTF-8')
        Rails.logger.debug "Successfully decrypted AES data (#{decrypted.bytesize} bytes)"
        Rails.logger.debug "First 64 chars of decrypted data: #{decrypted[0..63]}"
        
        # Verify the decrypted data is valid UTF-8
        unless decrypted.valid_encoding?
          Rails.logger.error "Decrypted data is not valid UTF-8"
          raise DecryptionError, "Decrypted data is not valid UTF-8"
        end
        
        decrypted
      rescue OpenSSL::Cipher::CipherError => e
        Rails.logger.error "AES decryption failed: #{e.message}"
        Rails.logger.error "Cipher parameters:"
        Rails.logger.error " - Algorithm: #{cipher.name}"
        Rails.logger.error " - Key length: #{cipher.key_len} bytes"
        Rails.logger.error " - IV length: #{cipher.iv_len} bytes"
        Rails.logger.error " - Auth tag length: #{auth_tag.length} bytes"
        raise DecryptionError, "AES decryption failed: #{e.message}"
      end
    end

    def verify_and_decode_jwt(token)
      # Decode and verify the JWT using the RSA private key
      begin
        Rails.logger.debug "Verifying JWT token"
        decoded = JWT.decode(
          token,
          KeyManagementService.rsa_private_key,
          true,
          {
            algorithm: 'RS256',
            verify_iat: true,
            verify_aud: true,
            aud: ENV['COGNITO_CLIENT_ID'],  # Use Cognito client ID as the audience
            verify_iss: true,
            iss: ENV['JWT_ISSUER'] || 'sso-service'  # Match the issuer from the TypeScript service
          }
        ).first
        Rails.logger.debug "JWT verification successful"
        decoded
      rescue JWT::InvalidIssuerError => e
        Rails.logger.error "JWT issuer verification failed: Expected #{ENV['JWT_ISSUER']}, got #{e.message}"
        raise DecryptionError, "Invalid JWT issuer: #{e.message}"
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT verification failed: #{e.message}"
        raise DecryptionError, "Invalid JWT token: #{e.message}"
      end
    end

    def extract_token_components
      parts = @encrypted_token.split('.')
      raise DecryptionError, "Invalid token format" unless parts.length == 3
      
      # Convert base64 components to binary
      begin
        iv = Base64.strict_decode64(parts[0])
        auth_tag = Base64.strict_decode64(parts[1])
        encrypted_data = Base64.strict_decode64(parts[2])

        Rails.logger.debug "Base64 decoded components:"
        Rails.logger.debug " - IV (base64): #{parts[0]}"
        Rails.logger.debug " - Auth Tag (base64): #{parts[1]}"
        Rails.logger.debug " - Encrypted Data (base64, first 64 chars): #{parts[2][0..63]}"

        [iv, auth_tag, encrypted_data]
      rescue ArgumentError => e
        Rails.logger.error "Failed to decode base64 components: #{e.message}"
        raise DecryptionError, "Invalid base64 encoding in token components"
      end
    end

    def debug_token_format(encrypted_token)
      parts = encrypted_token.split('.')
      {
        parts_count: parts.length,
        parts_sizes: parts.map { |p| Base64.strict_decode64(p).length }
      }
    rescue StandardError => e
      { error: "Failed to analyze token format: #{e.message}" }
    end
  end
end 