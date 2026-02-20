# -------------------------------------------------------
# General
# -------------------------------------------------------

variable "create_cognitopool" {
  description = "Whether to create the Cognito User Pool and all related resources."
  type        = bool
  default     = false
}

variable "resource_tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    env  = "dev"
    Iaac = "terraform"
  }
}

# -------------------------------------------------------
# User Pool
# -------------------------------------------------------

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool."
  type        = string
  default     = "cognito_dev_pool_ap1"
}

# username_attributes is hardcoded to ["email"] in cognitomain.tf
# alias_attributes is not used — the two are mutually exclusive in Cognito

variable "auto_verified_attributes" {
  description = "Attributes to auto-verify upon user sign-up."
  type        = list(string)
  default     = ["email"]
}

variable "case_sensitive" {
  description = "Whether usernames are treated as case-sensitive."
  type        = bool
  default     = false
}

# -------------------------------------------------------
# Email Configuration
# -------------------------------------------------------
# Email is sent via Cognito built-in (COGNITO_DEFAULT).
# No SES ARN or from-address needed — Cognito handles it.
# To switch to SES later, change email_sending_account to
# DEVELOPER and add source_arn + from_email_address.

# -------------------------------------------------------
# Google Identity Provider (optional)
# -------------------------------------------------------

variable "enable_google_idp" {
  description = "Set to true to enable Google as a social identity provider. Requires google_client_id and google_client_secret."
  type        = bool
  default     = false
}

variable "google_client_id" {
  description = "Google OAuth 2.0 Client ID. Only used when enable_google_idp = true."
  type        = string
  sensitive   = true
  default     = ""
}

variable "google_client_secret" {
  description = "Google OAuth 2.0 Client Secret. Only used when enable_google_idp = true."
  type        = string
  sensitive   = true
  default     = ""
}

# -------------------------------------------------------
# App Client
# -------------------------------------------------------

variable "cognito_user_pool_client" {
  description = "Name of the Cognito User Pool App Client."
  type        = string
  default     = "cognito_dev_client_ap1"
}

variable "refresh_token_validity" {
  description = "How long (in days) the refresh token is valid."
  type        = number
  default     = 5
}

variable "access_token_validity" {
  description = "How long (in minutes) the access token is valid."
  type        = number
  default     = 60
}

variable "id_token_validity" {
  description = "How long (in minutes) the ID token is valid."
  type        = number
  default     = 60
}

variable "auth_session_validity" {
  description = "How long (in minutes) the authentication flow session is valid (1–15)."
  type        = number
  default     = 3
}

# -------------------------------------------------------
# OAuth / Managed Login
# -------------------------------------------------------

variable "cognito_user_pool_domain" {
  description = "Cognito domain prefix for the hosted UI / managed login page."
  type        = string
  default     = "verbaldev"
}

variable "allowed_oauth_flows_user_pool_client" {
  description = "Whether to enable OAuth flows on the app client."
  type        = bool
  default     = true
}

variable "allowed_oauth_flows" {
  description = "OAuth 2.0 grant types. Use 'code' for Authorization Code and 'implicit' for Implicit Grant."
  type        = list(string)
  default     = ["code", "implicit"]
}

variable "allowed_oauth_scopes" {
  description = "OIDC scopes the app client is allowed to request."
  type        = list(string)
  default = [
    "openid",
    "email",
    "profile",
    "aws.cognito.signin.user.admin",
  ]
}

variable "callback_urls" {
  description = "Allowed OAuth callback (redirect) URLs after login."
  type        = list(string)
  default = [
    "https://d3uzalbslulagz.cloudfront.net/",
    "https://front.dev.tryverbal.com/",
  ]
}

variable "logout_urls" {
  description = "Allowed sign-out redirect URLs."
  type        = list(string)
  default = [
    "https://d3uzalbslulagz.cloudfront.net/",
    "https://front.dev.tryverbal.com/",
  ]
}

variable "supported_identity_providers" {
  description = "Identity providers the app client supports. Add 'Google' here when enable_google_idp = true."
  type        = list(string)
  default     = ["COGNITO"]
}

# -------------------------------------------------------
# Resource Server
# -------------------------------------------------------

variable "resource_server_identifier" {
  description = "Unique identifier for the resource server (your API). Becomes the scope prefix e.g. verbal-app-dev-aws/read"
  type        = string
  default     = "verbal-app-dev-aws"
}

variable "resource_server_name" {
  description = "Friendly display name for the resource server shown in AWS console."
  type        = string
  default     = "verbal-app-dev-aws"
}

variable "resource_server_scopes" {
  description = "List of custom scopes for the resource server. Each scope becomes <identifier>/<scope_name> in the access token."
  type = list(object({
    scope_name        = string
    scope_description = string
  }))
  default = [
    {
      scope_name        = "read"
      scope_description = "Read access to the API"
    }
  ]
}
