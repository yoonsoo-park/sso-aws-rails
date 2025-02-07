variable "aws_region" {
  description = "TESTING SSO INTEGRATION - AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "TESTING SSO INTEGRATION - Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cognito_callback_url" {
  description = "TESTING SSO INTEGRATION - Callback URL for Cognito authentication"
  type        = string
  default     = "http://localhost:3000/auth/callback"
}

variable "cognito_logout_url" {
  description = "TESTING SSO INTEGRATION - Logout URL for Cognito"
  type        = string
  default     = "http://localhost:3000/auth/logout"
}

variable "cognito_domain_prefix" {
  description = "TESTING SSO INTEGRATION - Prefix for the Cognito domain"
  type        = string
  default     = "sso-testing"
}

variable "google_client_id" {
  description = "TESTING SSO INTEGRATION - Google OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "TESTING SSO INTEGRATION - Google OAuth Client Secret"
  type        = string
  sensitive   = true
} 