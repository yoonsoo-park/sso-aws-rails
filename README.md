# AWS Cognito SSO Rails Integration

This Rails application implements a secure Single Sign-On (SSO) integration with AWS Cognito, featuring token-based authentication with advanced encryption.

## Features

### SSO Integration

- Seamless authentication with AWS Cognito
- JWT token validation and verification
- AES-256-GCM token encryption for secure transmission
- RSA-256 signature verification
- User synchronization from Cognito claims

### Security

- Secure key management for encryption
- Environment-based configuration
- HTTPS enforcement (production)
- Comprehensive session management
- Secure token transmission

## Prerequisites

- Ruby 3.3.0
- PostgreSQL
- Node.js 20.18.1 (for the SSO service)
- AWS Account with Cognito User Pool

## Installation

1. **Clone the repository**

```bash
git clone [repository-url]
cd sso-aws-rails
```

2. **Install dependencies**

```bash
bundle install
```

3. **Set up configuration files**

```bash
# Copy example configuration files
cp .env.example .env
cp config/database.yml.example config/database.yml

# Generate encryption keys
mkdir -p config/keys
openssl genrsa -out config/keys/private.pem 2048
openssl rsa -in config/keys/private.pem -pubout -out config/keys/public.pem
```

4. **Set up the database**

```bash
rails db:create db:migrate
```

## Configuration

### Environment Variables

Update your `.env` file with the following configurations:

```env
# Rails Application Configuration
RAILS_ENV=development
PORT=3000

# Database Configuration
DATABASE_URL=postgresql://localhost/sso_aws_rails_development

# JWT Configuration
JWT_ISSUER=cognito-sso-service
JWT_AUDIENCE=your-rails-app

# AWS Cognito Configuration
AWS_REGION=us-east-1
COGNITO_USER_POOL_ID=your-pool-id
COGNITO_CLIENT_ID=your-client-id
COGNITO_CLIENT_SECRET=your-client-secret
```

### Security Keys

1. **RSA Keys**: Used for JWT token signing/verification

   - Located in `config/keys/`
   - private.pem: JWT signing
   - public.pem: JWT verification

2. **AES Encryption Key**: Used for token encryption
   - 32-byte key for AES-256-GCM
   - Set in environment variables

## Technical Details

### JWT Token Format

The application expects JWTs with the following structure:

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "cognito-user-sub-id",
    "email": "user@example.com",
    "given_name": "John",
    "family_name": "Doe",
    "iss": "cognito-sso-service",
    "aud": "your-rails-app",
    "exp": 1707408000,
    "iat": 1707404400
  }
}
```

### Token Encryption Process

1. **JWT Generation** (in SSO Service):

```typescript
// Example JWT token generation
const token = jwt.sign(payload, privateKey, {
  algorithm: "RS256",
  expiresIn: "1h",
});

// AES-256-GCM encryption
const iv = crypto.randomBytes(12);
const cipher = crypto.createCipheriv("aes-256-gcm", aesKey, iv);
const encrypted = Buffer.concat([cipher.update(token), cipher.final()]);
const authTag = cipher.getAuthTag();

// Format: base64(iv).base64(authTag).base64(encrypted)
const encryptedToken = [
  iv.toString("base64"),
  authTag.toString("base64"),
  encrypted.toString("base64"),
].join(".");
```

2. **Token Decryption** (in Rails):

```ruby
# Example decryption in TokenDecryptionService
def decrypt_aes
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.decrypt
  cipher.key = KeyManagementService.aes_encryption_key

  iv, auth_tag, encrypted_data = extract_token_components
  cipher.iv = iv
  cipher.auth_tag = auth_tag

  cipher.update(encrypted_data) + cipher.final
end
```

### User Synchronization Examples

1. **User Creation from Claims**:

```ruby
# Example user creation from JWT claims
user = User.find_or_initialize_by(cognito_sub: claims['sub'])
user.assign_attributes(
  email: claims['email'],
  given_name: claims['given_name'],
  family_name: claims['family_name'],
  last_sign_in_at: Time.current
)
user.save!
```

2. **Sample Claims Processing**:

```ruby
# Example claims processing in UserSynchronizationService
def process_claims(claims)
  {
    cognito_sub: claims['sub'],
    email: claims['email'],
    given_name: claims['given_name'],
    family_name: claims['family_name'],
    # Additional attributes
    email_verified: claims['email_verified'],
    custom_attributes: claims.slice(*CUSTOM_ATTRIBUTE_KEYS)
  }
end
```

## API Examples

### 1. SSO Authentication Flow

#### Request Example:

```bash
curl -X POST http://localhost:3000/auth/v1/control_plane_sso \
  -H "Content-Type: application/json" \
  -d '{
    "token": "base64iv.base64authtag.base64encrypteddata",
    "state": "random-state-string"
  }'
```

#### Success Response:

```json
{
  "message": "Authentication successful",
  "user": {
    "id": 1,
    "email": "john.doe@example.com",
    "given_name": "John",
    "family_name": "Doe"
  }
}
```

#### Error Response:

```json
{
  "error": "Invalid token",
  "details": "Token has expired"
}
```

### 2. Environment Setup Examples

#### Generate AES Key:

```bash
# Generate a secure 32-byte key for AES-256-GCM
openssl rand -hex 32
```

#### Format RSA Private Key for ENV:

```bash
# Convert private key to single line with \n
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' config/keys/private.pem
```

## Common Operations

### 1. Key Management

```ruby
# Example key rotation in KeyManagementService
class KeyManagementService
  def self.rotate_aes_key!
    new_key = SecureRandom.hex(32)
    old_key = ENV['AES_ENCRYPTION_KEY']

    ENV['AES_ENCRYPTION_KEY'] = new_key
    ENV['AES_ENCRYPTION_KEY_OLD'] = old_key

    reset_keys!
  end
end
```

### 2. User Session Management

```ruby
# Example session creation
def create_user_session(user)
  session[:user_id] = user.id
  session[:last_activity] = Time.current
  session[:expires_at] = 1.hour.from_now
end

# Example session validation
def validate_session
  return false if session[:expires_at].nil? ||
                 Time.current > session[:expires_at]

  session[:last_activity] = Time.current
  session[:expires_at] = 1.hour.from_now
  true
end
```

## Testing Examples

### 1. Controller Tests

```ruby
RSpec.describe Auth::V1::ControlPlaneSsoController, type: :controller do
  describe 'POST #create' do
    let(:encrypted_token) { generate_test_token }

    it 'successfully authenticates with valid token' do
      post :create, params: {
        token: encrypted_token,
        state: 'test-state'
      }

      expect(response).to have_http_status(:ok)
      expect(json_response[:user]).to include(:email)
    end
  end
end
```

### 2. Service Tests

```ruby
RSpec.describe Auth::TokenDecryptionService do
  describe '#decrypt' do
    it 'successfully decrypts valid token' do
      service = described_class.new(encrypted_token)
      claims = service.decrypt

      expect(claims).to include('sub', 'email')
    end
  end
end
```

## Troubleshooting Examples

### 1. Token Validation Issues

```ruby
# Debug token format
def debug_token_format(encrypted_token)
  parts = encrypted_token.split('.')
  unless parts.length == 3
    raise "Invalid token format. Expected 3 parts, got #{parts.length}"
  end

  {
    iv: Base64.decode64(parts[0]).length,
    auth_tag: Base64.decode64(parts[1]).length,
    encrypted_data: Base64.decode64(parts[2]).length
  }
end
```

### 2. Database Connection Issues

```bash
# Check database connection
RAILS_ENV=development rails dbconsole

# Verify environment variables
rails runner "puts ENV['DATABASE_URL']"
```

## User Synchronization

The application automatically synchronizes user data from Cognito claims:

- Creates/updates users based on Cognito information
- Maintains user attributes (email, name, etc.)
- Tracks last sign-in time

## Security Considerations

1. **Key Management**

   - Store encryption keys securely
   - Use environment variables for sensitive data
   - Rotate keys periodically

2. **Token Security**

   - AES-256-GCM encryption for token transmission
   - RSA-256 for JWT signing
   - Short token expiration times

3. **Environment Security**
   - HTTPS enforcement in production
   - Secure headers configuration
   - Session timeout management

## Development

### Running the Application

```bash
# Start the Rails server
rails server

# Run tests
rspec
```

### Adding New Features

1. Create a feature branch
2. Write tests
3. Implement the feature
4. Submit a pull request

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific tests
bundle exec rspec spec/controllers/auth/v1/control_plane_sso_controller_spec.rb
```

## Troubleshooting

### Common Issues

1. **Token Validation Errors**

   - Check JWT issuer and audience configuration
   - Verify RSA key pair matches
   - Ensure token hasn't expired

2. **Encryption Issues**

   - Verify AES key length (32 bytes)
   - Check encryption format (IV + ciphertext + auth tag)

3. **User Synchronization Problems**
   - Verify Cognito claims format
   - Check database constraints
   - Review user attribute mapping

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
