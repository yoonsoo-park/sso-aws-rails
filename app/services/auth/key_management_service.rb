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
          raw_key = ENV['AES_ENCRYPTION_KEY']
          raise KeyError, "Missing AES encryption key" unless raw_key
          
          # Convert the hex string to binary if needed
          raw_key.length == 64 ? [raw_key].pack('H*') : raw_key
        end
      end

      def reset_keys!
        @rsa_private_key = nil
        @aes_encryption_key = nil
      end
    end
  end
end 