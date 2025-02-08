module Auth
  class KeyManagementService
    class KeyError < StandardError; end

    class << self
      def rsa_private_key
        @rsa_private_key ||= begin
          raw_key = ENV['RSA_PRIVATE_KEY'] || File.read(Rails.root.join('config', 'keys', 'private.pem'))
          OpenSSL::PKey::RSA.new(raw_key)
        rescue StandardError => e
          Rails.logger.error("Failed to load RSA private key: #{e.message}")
          raise KeyError, "Failed to load RSA private key"
        end
      end

      def aes_encryption_key
        @aes_encryption_key ||= begin
          # In production, this should come from a secure key management service
          # For testing, we'll use an environment variable
          raw_key = ENV['ENCRYPTION_KEY']
          raise KeyError, "Missing AES encryption key" unless raw_key
          
          Rails.logger.debug "Raw encryption key length: #{raw_key.length} characters"
          
          # Convert hex string to binary
          begin
            binary_key = [raw_key].pack('H*')
            Rails.logger.debug "Converted to binary key (#{binary_key.bytesize} bytes)"
            binary_key
          rescue ArgumentError => e
            Rails.logger.error "Failed to convert encryption key from hex: #{e.message}"
            Rails.logger.error "Raw key: #{raw_key}"
            raise KeyError, "Invalid encryption key format: must be a hex string"
          end
        end
      end

      def reset_keys!
        @rsa_private_key = nil
        @aes_encryption_key = nil
      end
    end
  end
end 