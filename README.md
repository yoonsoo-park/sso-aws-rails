# SSO Rails Integration Testing

This project provides a testing environment for validating the integration between Single Sign-On (SSO) services and a Ruby on Rails application. The setup focuses on secure token generation, encryption, and exchange between services.

## Components

1. **TypeScript SSO Service**: A lightweight Identity Provider (IdP) that:

   - Generates and signs JWT tokens using RSA-256
   - Encrypts tokens using AES-256-GCM
   - Provides authentication endpoints
   - Manages secure token transmission
   - Implements comprehensive error handling and logging
   - Includes request validation middleware

2. **Rails Application**: Includes an SSO module that:
   - Receives encrypted tokens
   - Decrypts tokens using the same encryption key
   - Validates JWT claims
   - Manages user sessions

## Project Structure

```
.
├── .tool-versions        # asdf version manager configuration
├── README.md            # Main project documentation
├── private.pem          # RSA private key for JWT signing
├── public.pem           # RSA public key for JWT verification
└── sso-service/         # TypeScript-based SSO service
    ├── src/            # Source code
    │   ├── controllers/
    │   ├── services/
    │   ├── middleware/
    │   └── utils/
    ├── test/           # Test files
    ├── terraform/      # Infrastructure as code
    ├── scripts/        # Utility scripts
    │   └── setup-env.sh
    ├── .env           # Environment configuration
    ├── .env.example   # Environment template
    ├── package.json   # Node.js dependencies
    └── tsconfig.json  # TypeScript configuration
```

## Prerequisites

- Node.js (v20.11.0 via asdf)
- Ruby (3.2.0 via asdf)
- Terraform (1.7.0 via asdf)

## Detailed Setup Instructions

### 1. Environment Setup

First, ensure you have the correct versions of required tools using asdf:

```bash
# Create .tool-versions file
cat > .tool-versions << EOL
nodejs 20.11.0
ruby 3.2.0
terraform 1.7.0
EOL

# Install specified versions
asdf install
```

### 2. SSO Service Setup

#### a. Install Dependencies

```bash
cd sso-service
npm install
```

This installs:

- Express for the web server
- jsonwebtoken for JWT handling
- TypeScript and related tools for development
- AWS SDK for Cognito integration

#### b. Generate RSA Keys for JWT Signing

```bash
# Generate private key
openssl genrsa -out private.pem 2048

# Generate public key for verification
openssl rsa -in private.pem -pubout -out public.pem
```

The private key is used to sign JWTs, while the public key can verify the signature. This asymmetric encryption ensures that tokens can only be created by the authorized SSO service.

#### c. Configure Environment Variables

There are two ways to set up your environment:

1. **Using the Setup Script (Recommended)**:

```bash
# Make the setup script executable
chmod +x scripts/setup-env.sh

# Run the setup script
./scripts/setup-env.sh
```

The script will:

- Check for the existence of private.pem
- Create .env from .env.example if it doesn't exist
- Format and set the JWT_PRIVATE_KEY automatically
- Generate a secure encryption key
- Provide guidance for setting other required variables

2. **Manual Setup**:

```bash
# Copy the example env file
cp .env.example .env

# Generate a secure encryption key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Format and set the private key in .env
# Replace JWT_PRIVATE_KEY with the contents of private.pem
# Note: The key must be in a single line with \n for newlines
```

Required environment variables:

- `PORT`: Service port (default: 3000)
- `JWT_PRIVATE_KEY`: RSA private key for JWT signing
- `JWT_ISSUER`: Token issuer identifier
- `JWT_AUDIENCE`: Token audience (Rails app)
- `ENCRYPTION_KEY`: 64-character hex string (32 bytes) for AES-256-GCM encryption
- `RAILS_APP_URL`: URL of the Rails application
- `AWS_REGION`: AWS region for Cognito (e.g., us-east-1)
- `COGNITO_USER_POOL_ID`: Cognito User Pool ID
- `COGNITO_CLIENT_ID`: Cognito App Client ID
- `COGNITO_CLIENT_SECRET`: Cognito App Client Secret
- `COGNITO_DOMAIN`: Cognito domain URL
- `COGNITO_CALLBACK_URL`: Callback URL for Cognito authentication

#### d. AWS Cognito Setup

1. **Deploy Cognito Resources**:

```bash
cd sso-service/terraform
terraform init
terraform apply
```

2. **Retrieve Cognito Configuration**:
   After applying Terraform, you'll get outputs for most Cognito values. However, the client secret is marked as sensitive and needs to be retrieved separately:

```bash
# Get the client secret
cd sso-service/terraform
terraform output -raw cognito_client_secret
```

3. **Update Environment Variables**:
   Update your `.env` file with the Cognito configuration:

```bash
COGNITO_USER_POOL_ID=<from terraform output>
COGNITO_CLIENT_ID=<from terraform output>
COGNITO_CLIENT_SECRET=<from terraform output -raw cognito_client_secret>
COGNITO_DOMAIN=<from terraform output>
```

### 3. Testing Setup

The project includes comprehensive tests to verify:

- JWT token generation and signing
- Token encryption/decryption
- Authentication flow

#### a. Configure Test Environment

```bash
# Install test dependencies
npm install jest ts-jest @types/jest --save-dev

# Create Jest configuration
# jest.config.js is configured for TypeScript testing
```

#### b. Run Tests

```bash
npm test
```

Test coverage includes:

- Token generation with proper claims
- RSA signing verification
- AES-256-GCM encryption/decryption
- Error handling for missing keys
- Token format validation

### 4. Development Workflow

1. Start the SSO service:

```bash
npm run dev
```

2. Test SSO Authentication:

   - Visit `http://localhost:3000/auth/login` in your browser
   - You will be redirected to the Cognito hosted UI
   - After successful authentication, you'll be redirected back with an encrypted token

3. Verify token format and encryption:
   - Check JWT structure (header.payload.signature)
   - Verify encryption format (IV + ciphertext + auth tag)
   - Validate token claims

## Security Considerations

1. **Key Management**:

   - Private keys are never committed to version control
   - Secure encryption key generation and storage
   - Environment variables for sensitive data

2. **Token Security**:

   - RSA-256 for JWT signing
   - AES-256-GCM for token encryption
   - Short token expiration times

3. **Best Practices**:
   - HTTPS enforcement in production
   - Secure headers configuration
   - Proper error handling and logging

## Testing Strategy

1. **Unit Tests**:

   - Token generation and signing
   - Encryption/decryption
   - Claim validation

2. **Integration Tests**:

   - End-to-end token flow
   - Error scenarios
   - Concurrent token encryption
   - Configuration validation
   - Error handling validation

3. **Test Coverage Requirements**:
   - Minimum 80% branch coverage
   - Minimum 80% function coverage
   - Minimum 80% line coverage
   - Minimum 80% statement coverage

## Error Handling

The project implements a comprehensive error handling system:

1. **Custom Error Types**:

   - `BaseError`: Foundation for all custom errors
   - `AuthenticationError`: For authentication-related issues (401)
   - `ValidationError`: For request validation failures (400)
   - `ConfigurationError`: For environment/setup issues (500)
   - `EncryptionError`: For encryption failures (500)

2. **Global Error Handler**:

   - Centralized error processing
   - Consistent error response format
   - Automatic status code mapping
   - Detailed error logging

3. **Request Validation**:
   - Express-validator integration
   - Pre-request payload validation
   - Custom validation rules
   - Detailed validation error messages

## Logging System

The project uses Winston for structured logging:

1. **Log Levels**:

   - ERROR: For critical issues and exceptions
   - WARN: For potential issues and validation failures
   - INFO: For important operations and state changes
   - DEBUG: For detailed debugging information

2. **Log Format**:

   - Timestamp
   - Log level
   - Structured JSON output
   - Request context where applicable
   - Error stack traces for debugging

3. **Environment-specific Configuration**:
   - Production: INFO level with essential details
   - Development: DEBUG level with full context
   - Test: ERROR level for test runs

## Troubleshooting

Common issues and solutions:

1. **JWT Signing Errors**:

   - Verify private key format (PEM format with proper headers)
   - Check algorithm specification (RS256)
   - Validate key permissions

2. **Encryption Issues**:
   - Ensure encryption key is exactly 64 hex characters (32 bytes)
   - Verify encryption key format
   - Check for proper IV and auth tag handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See LICENSE file for details
