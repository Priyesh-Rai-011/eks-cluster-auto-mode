# -------------------------------------------------------
# User Pool
# -------------------------------------------------------
resource "aws_cognito_user_pool" "cognito_user_pool" {
  count = var.create_cognitopool ? 1 : 0

  name = var.cognito_user_pool_name

  # -------------------------------------------------------
  # Sign-in: email only (not username, not phone)
  # Use username_attributes instead of alias_attributes
  # -------------------------------------------------------
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # -------------------------------------------------------
  # MFA: OFF
  # -------------------------------------------------------
  mfa_configuration = "OFF"

  # -------------------------------------------------------
  # Email via Cognito built-in (no SES)
  # -------------------------------------------------------
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # -------------------------------------------------------
  # Account recovery: email first, SMS as fallback
  # -------------------------------------------------------
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }
  }

  # -------------------------------------------------------
  # Required standard attribute: email
  # -------------------------------------------------------
  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  # -------------------------------------------------------
  # Custom attributes
  # NOTE: Custom attribute names cannot be changed after
  # the user pool is created. They are always prefixed
  # with "custom:" in Cognito (e.g. custom:organizationId)
  # -------------------------------------------------------
  schema {
    attribute_data_type      = "String"
    mutable                  = true
    name                     = "organizationId"
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    attribute_data_type      = "String"
    mutable                  = true
    name                     = "role"
    required                 = false
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  tags = var.resource_tags
}

# -------------------------------------------------------
# Google Identity Provider (optional — gated by flag)
# -------------------------------------------------------
resource "aws_cognito_identity_provider" "google" {
  count        = var.create_cognitopool && var.enable_google_idp ? 1 : 0
  user_pool_id = aws_cognito_user_pool.cognito_user_pool[0].id

  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id        = var.google_client_id
    client_secret    = var.google_client_secret
    authorize_scopes = "email profile openid"
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}

# -------------------------------------------------------
# User Pool Client
# -------------------------------------------------------
resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  count        = length(aws_cognito_user_pool.cognito_user_pool) > 0 ? 1 : 0
  name         = var.cognito_user_pool_client
  user_pool_id = aws_cognito_user_pool.cognito_user_pool[count.index].id

  # No client secret (public client)
  generate_secret = false

  # Auth flows:
  #   ALLOW_USER_AUTH          = Choice-based sign-in (umbrella flow)
  #   ALLOW_USER_PASSWORD_AUTH = Username + password
  #   ALLOW_USER_SRP_AUTH      = Secure Remote Password (SRP)
  #   ALLOW_REFRESH_TOKEN_AUTH = Get tokens from existing session
  explicit_auth_flows = [
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  # OAuth / Managed Login
  allowed_oauth_flows_user_pool_client = var.allowed_oauth_flows_user_pool_client
  allowed_oauth_flows                  = var.allowed_oauth_flows
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  supported_identity_providers         = var.supported_identity_providers
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  # Token validity
  refresh_token_validity = var.refresh_token_validity
  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity

  token_validity_units {
    refresh_token = "days"
    access_token  = "minutes"
    id_token      = "minutes"
  }

  # Auth flow session duration
  auth_session_validity = var.auth_session_validity

  # Security hardening
  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  depends_on = [aws_cognito_identity_provider.google]
}

# -------------------------------------------------------
# User Pool Domain (Managed Login / Hosted UI)
# -------------------------------------------------------
resource "aws_cognito_user_pool_domain" "cognito_domain" {
  count        = length(aws_cognito_user_pool.cognito_user_pool) > 0 ? 1 : 0
  domain       = var.cognito_user_pool_domain
  user_pool_id = aws_cognito_user_pool.cognito_user_pool[count.index].id
}

# -------------------------------------------------------
# Resource Server
# Registers your API with Cognito so access tokens can
# carry custom scopes (e.g. verbal-app-dev-aws/read)
# -------------------------------------------------------
resource "aws_cognito_resource_server" "resource_server" {
  count        = length(aws_cognito_user_pool.cognito_user_pool) > 0 ? 1 : 0
  user_pool_id = aws_cognito_user_pool.cognito_user_pool[count.index].id

  # Identifier — must be unique within the user pool.
  # Typically a URL or a short name. This becomes the
  # prefix on every scope: <identifier>/<scope_name>
  identifier = var.resource_server_identifier

  # Friendly display name shown in the AWS console
  name = var.resource_server_name

  # Custom scopes — added to the access token's scope claim
  dynamic "scope" {
    for_each = var.resource_server_scopes
    content {
      scope_name        = scope.value.scope_name
      scope_description = scope.value.scope_description
    }
  }
}
