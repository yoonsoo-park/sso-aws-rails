#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting SSO Flow Test${NC}"

# 1. Check if nodemon is running (SSO Service on 3001)
echo -e "\n${BLUE}Checking SSO Service (Node.js)...${NC}"
if ! nc -z localhost 3001; then
    echo -e "${RED}SSO Service is not running. Starting it...${NC}"
    cd sso-service && npm run dev &
    sleep 5
else
    echo -e "${GREEN}SSO Service is running on port 3001${NC}"
fi

# 2. Check if Rails server is running (on 3001)
echo -e "\n${BLUE}Checking Rails Server...${NC}"
if ! nc -z localhost 3001; then
    echo -e "${RED}Rails server is not running. Starting it...${NC}"
    cd .. && rails server -p 3001 &
    sleep 5
else
    echo -e "${GREEN}Rails server is running on port 3001${NC}"
fi

# 3. Open Google SSO login page
echo -e "\n${BLUE}Opening Google SSO login page...${NC}"
COGNITO_DOMAIN="sso-testing.auth.us-east-1.amazoncognito.com"
AWS_REGION="us-east-1"
CLIENT_ID="2giaiin7rvjvnrm8osbvr1oorn"
REDIRECT_URI="http://localhost:3001/auth/callback"

SSO_URL="https://${COGNITO_DOMAIN}/oauth2/authorize?\
client_id=${CLIENT_ID}&\
response_type=code&\
scope=openid+email+profile&\
redirect_uri=${REDIRECT_URI}&\
identity_provider=Google"

echo -e "${GREEN}Opening browser for Google SSO...${NC}"
open "${SSO_URL}"

# 4. Wait for token from SSO service
echo -e "\n${BLUE}Waiting for encrypted JWT token...${NC}"
echo "Please complete the Google login in your browser."
echo "The SSO service will log the encrypted token."
echo -e "${GREEN}Check the SSO service logs for the encrypted token${NC}"

# 5. Instructions for testing Rails authentication
echo -e "\n${BLUE}To test Rails authentication:${NC}"
echo "1. Copy the encrypted token from the SSO service logs"
echo "2. Run the following curl command (replace TOKEN with the encrypted token):"
echo -e "${GREEN}"
echo 'curl -X POST http://localhost:3001/auth/v1/control_plane_sso \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '"'"'{"token": "TOKEN", "state": "test-state"}'"'"' \'
echo '  -c cookies.txt'
echo -e "${NC}"

# 6. Instructions for verifying session
echo -e "\n${BLUE}To verify the session:${NC}"
echo "Run the following command:"
echo -e "${GREEN}"
echo 'curl -X GET http://localhost:3001/api/v1/protected-resource \'
echo '  -b cookies.txt'
echo -e "${NC}"

echo -e "\n${BLUE}Test script complete. Follow the instructions above to complete the testing.${NC}" 