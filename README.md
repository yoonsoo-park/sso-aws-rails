# AWS Cognito SSO Rails Integration

This Rails application implements a secure Single Sign-On (SSO) integration with AWS Cognito, featuring token-based authentication with advanced encryption.

## Features

### SSO Integration

- Seamless authentication with AWS Cognito
- JWT token validation and verification
- AES-256-GCM token encryption for secure transmission
- RSA-256 signature verification
- User synchronization from Cognito claims
- Support for both API and browser-based authentication flows

### Security

- Secure key management for encryption
- Environment-based configuration
- HTTPS enforcement (production)
- Comprehensive session management with timeout and inactivity checks
- Secure token transmission
- CSRF protection with proper API/browser request handling

### User Interface

- Clean, modern authentication UI
- Success and error pages for browser-based flows
- Proper handling of both HTML and JSON responses
- User-friendly error messages and notifications

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
PORT=3001

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

# AES Encryption Configuration
AES_ENCRYPTION_KEY=your-32-byte-key
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
curl -X POST http://localhost:3001/auth/v1/control_plane_sso \
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
# Session creation with user info and timeout
def create_user_session(user)
  session[:user_id] = user.id
  session[:last_activity] = Time.current.to_i
  session[:expires_at] = 1.hour.from_now.to_i

  # Store minimal user info in session
  session[:user_info] = {
    email: user.email,
    given_name: user.given_name,
    family_name: user.family_name
  }
end

# Comprehensive session validation
def valid_session?
  return false if session[:user_id].blank? ||
                 session[:expires_at].blank? ||
                 session[:last_activity].blank?

  # Check absolute expiration
  return false if Time.current.to_i > session[:expires_at]

  # Check inactivity timeout (30 minutes)
  return false if Time.current.to_i - session[:last_activity] > 30.minutes

  # Auto-update last activity
  session[:last_activity] = Time.current.to_i
  true
end

# Session destruction for logout
def destroy_user_session
  reset_session
end
```

## Session Configuration

The application uses secure cookie-based sessions with the following configuration:

```ruby
config.middleware.use ActionDispatch::Session::CookieStore,
  key: '_sso_aws_rails_session',
  secure: Rails.env.production?,
  expire_after: 1.hour,
  same_site: :lax
```

### Session Security Features

1. **Timeout Mechanisms**

   - Absolute timeout: 1 hour from creation
   - Inactivity timeout: 30 minutes
   - Automatic activity tracking

2. **Security Headers**

   - Secure cookies in production
   - SameSite cookie policy
   - HTTPS enforcement
   - CSRF protection for browser-based requests

3. **Session Data**
   - Minimal user info storage
   - Encrypted session cookies
   - Automatic session cleanup

### API Endpoints

#### 1. SSO Authentication (Creates Session)

```bash
# Browser-based flow (HTML response)
GET /auth/v1/control_plane_sso?token=encrypted_token&state=random_state

# API flow (JSON response)
POST /auth/v1/control_plane_sso
Content-Type: application/json

{
  "token": "encrypted_token",
  "state": "random_state"
}
```

Response (JSON):

```json
{
  "message": "Authentication successful",
  "user": {
    "id": 1,
    "email": "john.doe@example.com",
    "given_name": "John",
    "family_name": "Doe"
  },
  "session": {
    "expires_at": 1707408000
  }
}
```

#### 2. Logout (Destroys Session)

```bash
DELETE /auth/v1/control_plane_sso
```

Response:

```json
{
  "message": "Logged out successfully"
}
```

### Authentication UI

The application provides user-friendly pages for browser-based authentication:

1. **Success Page**

   - Clean, modern design
   - Success message with session information
   - Auto-close functionality

2. **Error Page**
   - Clear error messaging
   - Retry authentication option
   - Helpful troubleshooting information

## Error Handling

The application provides comprehensive error handling for both API and browser-based flows:

1. **API Responses**

   - Structured JSON error messages
   - Appropriate HTTP status codes
   - Detailed error information for debugging

2. **Browser Responses**
   - User-friendly error pages
   - Clear error messages
   - Automatic redirection
   - Retry options

## Testing Examples

### 1. Browser Flow Test

```bash
# Start the test flow
./scripts/test-sso-flow.sh

# This will:
# 1. Check and start required services
# 2. Open the Google SSO login page
# 3. Handle the authentication flow
# 4. Create a session
# 5. Redirect to success/error page
```

### 2. Controller Tests

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

#### AES Decryption and JWT Validation Debug Process

1. **Issue Identification**

   - Initial error: AES decryption failing without specific error message
   - Secondary error: JWT validation failing due to issuer mismatch

2. **Debug Steps Taken**

   - Added detailed logging in TypeScript encryption service

     - Logged encryption key in hex format
     - Logged IV and auth tag generation
     - Logged token components in both hex and base64

   - Enhanced Rails decryption service logging

     - Added hex format logging of key components
     - Improved token component extraction logging
     - Added detailed error messages for decryption process

   - Resolved JWT issuer mismatch
     - Updated JWT issuer configuration to match between services
     - Ensured consistent audience value using Cognito client ID

3. **Key Findings**

   - AES encryption/decryption working correctly with proper logging
   - JWT validation succeeded after aligning issuer configuration
   - Successful user authentication and session creation

4. **Solution Implementation**
   - Aligned JWT issuer configuration between services
   - Maintained consistent encryption key handling
   - Added comprehensive logging for future debugging

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

### Rebuilding and Deploying in Development

When making code changes to the Rails application, follow these steps to rebuild and deploy:

1. **Stop the Current Server**

   ```bash
   # Find the Rails server process
   ps aux | grep puma
   # Or use the process listening on port 3001
   lsof -i :3001

   # Kill the process
   kill -9 <PID>
   ```

2. **Update Dependencies** (if Gemfile was modified)

   ```bash
   bundle install
   ```

3. **Run Database Migrations** (if any new migrations)

   ```bash
   bundle exec rails db:migrate
   ```

4. **Clear Rails Cache**

   ```bash
   bundle exec rails tmp:cache:clear
   ```

5. **Start the Rails Server**

   ```bash
   # Start on port 3001 (assuming SSO service is on 3000)
   bundle exec rails server -p 3001
   ```

6. **Monitor Logs** (in a separate terminal)

   ```bash
   # Watch all logs
   tail -f log/development.log

   # Or filter for specific content (e.g., token-related logs)
   tail -f log/development.log | grep -i "token"
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

## End-to-End Testing Workflow

### Complete SSO Flow Testing

This guide demonstrates how to test the complete SSO flow from Google authentication through Cognito to Rails session creation.

#### Prerequisites

1. **Google OAuth Setup**

   ```bash
   # Set up Google OAuth credentials in Google Cloud Console
   CLIENT_ID=your-google-client-id
   CLIENT_SECRET=your-google-client-secret
   ```

2. **AWS Cognito Configuration**

   ```bash
   # Configure Cognito User Pool with Google as Identity Provider
   AWS_REGION=us-east-1
   COGNITO_USER_POOL_ID=your-pool-id
   COGNITO_CLIENT_ID=your-client-id
   COGNITO_CLIENT_SECRET=your-client-secret
   ```

3. **Rails Application Setup**
   ```bash
   # Ensure your Rails application is running
   rails server
   ```

### Testing Steps

1. **Initiate Google SSO Flow**

   ```bash
   # Start Google OAuth flow (replace with your Cognito hosted UI URL)
   open "https://{cognito-domain}.auth.{region}.amazoncognito.com/oauth2/authorize?
     client_id={client-id}&
     response_type=code&
     scope=openid+email+profile&
     redirect_uri=http://localhost:3000/auth/callback&
     identity_provider=Google"
   ```

2. **Capture Cognito JWT Token**

   ```bash
   # After Google authentication, Cognito will redirect with a code
   # Exchange code for tokens using AWS SDK
   aws cognito-idp initiate-auth \
     --client-id ${COGNITO_CLIENT_ID} \
     --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters USERNAME=${TEST_USER},PASSWORD=${TEST_PASSWORD}
   ```

3. **Test Token Encryption**

   ```typescript
   // Use the SSO service to encrypt the JWT token
   const token = await encryptToken(cognitoJwtToken);
   console.log("Encrypted Token:", token);
   ```

4. **Test Rails Authentication**

   ```bash
   # Send encrypted token to Rails endpoint
   curl -X POST http://localhost:3001/auth/v1/control_plane_sso \
     -H "Content-Type: application/json" \
     -d '{
       "token": "'$ENCRYPTED_TOKEN'",
       "state": "test-state"
     }' \
     -c cookies.txt
   ```

5. **Verify Session**
   ```bash
   # Test authenticated endpoint with session cookie
   curl -X GET http://localhost:3001/api/v1/protected-resource \
     -b cookies.txt
   ```

### Example Test Script

```bash
#!/bin/bash

# Configuration
source .env.test

# 1. Get Cognito JWT Token
echo "Getting Cognito token..."
COGNITO_RESPONSE=$(aws cognito-idp initiate-auth \
  --client-id ${COGNITO_CLIENT_ID} \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=${TEST_USER},PASSWORD=${TEST_PASSWORD})

JWT_TOKEN=$(echo $COGNITO_RESPONSE | jq -r '.AuthenticationResult.IdToken')

# 2. Encrypt token using SSO service
echo "Encrypting token..."
ENCRYPTED_TOKEN=$(curl -X POST http://localhost:3001/encrypt \
  -H "Content-Type: application/json" \
  -d "{\"token\": \"$JWT_TOKEN\"}" | jq -r '.encrypted_token')

# 3. Authenticate with Rails
echo "Authenticating with Rails..."
RAILS_RESPONSE=$(curl -X POST http://localhost:3001/auth/v1/control_plane_sso \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"$ENCRYPTED_TOKEN\",
    \"state\": \"test-state\"
  }" \
  -c cookies.txt)

# 4. Verify session
echo "Verifying session..."
VERIFY_RESPONSE=$(curl -X GET http://localhost:3001/api/v1/protected-resource \
  -b cookies.txt)

echo "Test complete!"
echo "Rails Response: $RAILS_RESPONSE"
echo "Verification Response: $VERIFY_RESPONSE"
```

### Testing with Jest (SSO Service)

```typescript
// __tests__/sso-flow.test.ts
import { encryptToken } from "../src/services/encryption.service";
import { generateToken } from "../src/services/token.service";

describe("SSO Flow", () => {
  it("should handle complete SSO flow", async () => {
    // 1. Mock Cognito JWT token
    const mockClaims = {
      sub: "test-user-id",
      email: "test@example.com",
      name: "Test User",
    };
    const jwtToken = await generateToken(mockClaims);

    // 2. Test token encryption
    const encryptedToken = await encryptToken(jwtToken);
    expect(encryptedToken).toMatch(
      /^[A-Za-z0-9+/=]+\.[A-Za-z0-9+/=]+\.[A-Za-z0-9+/=]+$/
    );

    // 3. Mock Rails authentication
    const railsResponse = await fetch(
      "http://localhost:3001/auth/v1/control_plane_sso",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: encryptedToken,
          state: "test-state",
        }),
      }
    );

    expect(railsResponse.status).toBe(200);
  });
});
```

### RSpec Tests (Rails)

```ruby
# spec/requests/auth/sso_flow_spec.rb
RSpec.describe 'SSO Flow', type: :request do
  let(:mock_cognito_token) { generate_mock_cognito_token }
  let(:encrypted_token) { encrypt_token(mock_cognito_token) }

  it 'handles complete SSO flow' do
    # 1. Test authentication endpoint
    post '/auth/v1/control_plane_sso',
         params: { token: encrypted_token, state: 'test-state' }

    expect(response).to have_http_status(:ok)
    expect(session[:user_id]).to be_present

    # 2. Test session persistence
    get '/api/v1/protected-resource'
    expect(response).to have_http_status(:ok)

    # 3. Test session expiry
    travel 2.hours do
      get '/api/v1/protected-resource'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

### Common Testing Issues

1. **Token Encryption Issues**

   - Verify AES key length and format
   - Check IV and auth tag generation
   - Ensure consistent Base64 encoding

2. **Session Problems**

   - Clear cookies between tests
   - Check session configuration
   - Verify timeout settings

3. **Cognito Configuration**
   - Validate Google IdP setup
   - Check token scopes
   - Verify redirect URIs

### Monitoring and Debugging

1. **SSO Service Logs**

   ```typescript
   logger.debug("Token encryption:", {
     tokenLength: token.length,
     ivLength: iv.length,
     authTagLength: authTag.length,
   });
   ```

2. **Rails Logs**
   ```ruby
   Rails.logger.debug("Session created: #{
     {
       user_id: session[:user_id],
       expires_at: Time.at(session[:expires_at])
     }
   }")
   ```
