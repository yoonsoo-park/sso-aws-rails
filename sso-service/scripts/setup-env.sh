#!/bin/bash

# Check if private.pem exists
if [ ! -f "../private.pem" ]; then
    echo "Error: private.pem not found in the parent directory"
    echo "Please run the following commands first:"
    echo "  openssl genrsa -out private.pem 2048"
    echo "  openssl rsa -in private.pem -pubout -out public.pem"
    exit 1
fi

# Create .env from example if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
fi

# Format private key for .env file
echo "Formatting private key..."
PRIVATE_KEY=$(cat ../private.pem | awk 'NF {sub(/\r/, ""); printf "%s\\n", $0}')

# Update JWT_PRIVATE_KEY in .env
echo "Updating JWT_PRIVATE_KEY in .env..."
sed -i.bak "/JWT_PRIVATE_KEY=/c\JWT_PRIVATE_KEY=\"$PRIVATE_KEY\"" .env

# Clean up backup file
rm -f .env.bak

# Check if Terraform has been initialized and applied
if [ -d "terraform/.terraform" ]; then
    echo "Checking for KMS key ID from Terraform output..."
    KMS_KEY_ID=$(terraform -chdir=terraform output -raw kms_key_id 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$KMS_KEY_ID" ]; then
        echo "Found KMS key ID: $KMS_KEY_ID"
        echo "Updating AWS_KMS_KEY_ID in .env..."
        sed -i.bak "s/AWS_KMS_KEY_ID=.*/AWS_KMS_KEY_ID=$KMS_KEY_ID/" .env
        rm -f .env.bak
    else
        echo "Note: KMS key ID not found in Terraform output."
        echo "Please run 'terraform init' and 'terraform apply' in the terraform directory"
        echo "Then update AWS_KMS_KEY_ID in your .env file with the output value"
    fi
fi

echo "Environment setup complete!"
echo "Please verify the contents of your .env file and update other variables as needed:"
echo "  - AWS_REGION"
if [ -z "$KMS_KEY_ID" ]; then
    echo "  - AWS_KMS_KEY_ID (after running Terraform)"
fi
echo "  - RAILS_APP_URL" 