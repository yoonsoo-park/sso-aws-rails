terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "sso_encryption_key" {
  description             = "TESTING SSO INTEGRATION - KMS key for SSO token encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = var.environment
    Project     = "sso-testing"
  }
}

resource "aws_kms_alias" "sso_key_alias" {
  name          = "alias/sso-encryption-key"
  target_key_id = aws_kms_key.sso_encryption_key.key_id
}

# Cognito User Pool
resource "aws_cognito_user_pool" "sso_pool" {
  name = "sso-testing-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  username_attributes = ["email"]
  auto_verified_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true

    string_attribute_constraints {
      min_length = 3
      max_length = 256
    }
  }

  # Remove advanced security features
  # user_pool_add_ons {
  #   advanced_security_mode = "ENFORCED"
  # }

  # Enable hosted UI
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Add identity providers
  tags = {
    Environment = var.environment
    Project     = "sso-testing"
  }
}

# Google Identity Provider
resource "aws_cognito_identity_provider" "google_provider" {
  user_pool_id  = aws_cognito_user_pool.sso_pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email profile openid"
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
    name     = "name"
  }
}

# Update the app client to support Google
resource "aws_cognito_user_pool_client" "sso_client" {
  name         = "sso-testing-client"
  user_pool_id = aws_cognito_user_pool.sso_pool.id

  generate_secret = true
  
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]

  callback_urls = [var.cognito_callback_url]
  logout_urls  = [var.cognito_logout_url]

  supported_identity_providers = ["COGNITO", "Google"]

  # Enable hosted UI
  prevent_user_existence_errors = "ENABLED"
}

# Cognito Domain
resource "aws_cognito_user_pool_domain" "sso_domain" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.sso_pool.id
}

# Output values
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.sso_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.sso_client.id
}

output "cognito_client_secret" {
  value     = aws_cognito_user_pool_client.sso_client.client_secret
  sensitive = true
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.sso_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

# IAM policy to allow the SSO service to use the KMS key
resource "aws_iam_policy" "sso_kms_policy" {
  name        = "sso-kms-policy"
  description = "TESTING SSO INTEGRATION - Policy to allow SSO service to use KMS key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [aws_kms_key.sso_encryption_key.arn]
      }
    ]
  })
} 