#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}SSO Configuration Helper${NC}"
echo -e "${BLUE}====================${NC}\n"

# AWS Configuration
echo -e "${BLUE}AWS Cognito Configuration${NC}"
echo -e "${GREEN}Follow these steps to get AWS Cognito values:${NC}"
echo "1. Go to AWS Console > Amazon Cognito"
echo "2. Select or create a User Pool"
echo "3. Copy the following values:"
echo "   - User Pool ID (General settings)"
echo "   - Client ID (App integration > App client list)"
echo "   - Domain (App integration > Domain)"
echo -e "\n"

# Prompt for AWS values
read -p "Enter Cognito Domain (e.g., your-domain.auth.region.amazoncognito.com): " COGNITO_DOMAIN
read -p "Enter AWS Region (e.g., us-east-1): " AWS_REGION
read -p "Enter Cognito User Pool ID: " USER_POOL_ID
read -p "Enter Client ID: " CLIENT_ID
read -p "Enter Client Secret: " CLIENT_SECRET

# Google OAuth Configuration
echo -e "\n${BLUE}Google OAuth Configuration${NC}"
echo -e "${GREEN}Follow these steps to get Google OAuth credentials:${NC}"
echo "1. Go to Google Cloud Console (https://console.cloud.google.com)"
echo "2. Select or create a project"
echo "3. Navigate to APIs & Services > Credentials"
echo "4. Create OAuth 2.0 Client ID"
echo "5. Add authorized redirect URIs:"
echo "   - https://${COGNITO_DOMAIN}/oauth2/idpresponse"
echo -e "\n"

read -p "Enter Google Client ID: " GOOGLE_CLIENT_ID
read -p "Enter Google Client Secret: " GOOGLE_CLIENT_SECRET

# Create/update environment files
echo -e "\n${BLUE}Creating environment files...${NC}"

# SSO Service .env
echo "Creating sso-service/.env..."
cat > sso-service/.env << EOL
PORT=3000
COGNITO_DOMAIN=${COGNITO_DOMAIN}
AWS_REGION=${AWS_REGION}
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
REDIRECT_URI=http://localhost:3001/auth/callback
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
EOL

# Rails .env
echo "Creating .env..."
cat > .env << EOL
# Rails Application Configuration
RAILS_ENV=development
PORT=3001

# JWT Configuration
JWT_ISSUER=${COGNITO_DOMAIN}
JWT_AUDIENCE=${CLIENT_ID}

# AWS Cognito Configuration
AWS_REGION=${AWS_REGION}
COGNITO_USER_POOL_ID=${USER_POOL_ID}
COGNITO_CLIENT_ID=${CLIENT_ID}
COGNITO_CLIENT_SECRET=${CLIENT_SECRET}
EOL

# Update test script with actual values
echo "Updating test-sso-flow.sh..."
sed -i '' "s/your-cognito-domain/${COGNITO_DOMAIN}/g" scripts/test-sso-flow.sh
sed -i '' "s/your-client-id/${CLIENT_ID}/g" scripts/test-sso-flow.sh

echo -e "\n${GREEN}Configuration complete!${NC}"
echo -e "Environment files have been created/updated:"
echo "- sso-service/.env"
echo "- .env"
echo "- scripts/test-sso-flow.sh"

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Configure Google OAuth in AWS Cognito:"
echo "   - Go to AWS Cognito > User Pool > Sign-in experience"
echo "   - Add Google as an identity provider"
echo "   - Use these values:"
echo "     Client ID: ${GOOGLE_CLIENT_ID}"
echo "     Client Secret: ${GOOGLE_CLIENT_SECRET}"
echo "2. Run the test script:"
echo "   ./scripts/test-sso-flow.sh" 