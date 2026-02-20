# ==============================================================
#  dev/cognito/terragrunt.hcl
#  Deploys the Cognito module for the dev environment
# ==============================================================

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  # Points to the local module — no remote GitHub reference needed
  source = "../../modules/cognito"
}

inputs = {
  # -----------------------------------------------------------
  # Feature flag
  # -----------------------------------------------------------
  create_cognitopool = true

  # -----------------------------------------------------------
  # User Pool
  # -----------------------------------------------------------
  cognito_user_pool_name   = "cognito_dev_pool_ap1"
  auto_verified_attributes = ["email"]
  case_sensitive           = false

  # -----------------------------------------------------------
  # Google IdP — set enable_google_idp = true when ready
  # -----------------------------------------------------------
  enable_google_idp    = false
  google_client_id     = ""   # fill in when enabling Google
  google_client_secret = ""   # fill in when enabling Google

  # -----------------------------------------------------------
  # App Client
  # -----------------------------------------------------------
  cognito_user_pool_client = "cognito_dev_client_ap1"

  refresh_token_validity = 5    # days
  access_token_validity  = 60   # minutes
  id_token_validity      = 60   # minutes
  auth_session_validity  = 3    # minutes

  # -----------------------------------------------------------
  # OAuth / Managed Login
  # -----------------------------------------------------------
  cognito_user_pool_domain             = "verbaldev"
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
    "aws.cognito.signin.user.admin",
  ]

  callback_urls = [
    "https://d3uzalbslulagz.cloudfront.net/",
    "https://front.dev.tryverbal.com/",
  ]

  logout_urls = [
    "https://d3uzalbslulagz.cloudfront.net/",
    "https://front.dev.tryverbal.com/",
  ]

  supported_identity_providers = ["COGNITO"]   # add "Google" when IdP is enabled

  # -----------------------------------------------------------
  # Resource Server
  # -----------------------------------------------------------
  resource_server_identifier = "verbal-app-dev-aws"
  resource_server_name       = "verbal-app-dev-aws"
  resource_server_scopes = [
    {
      scope_name        = "read"
      scope_description = "Read access to the API"
    },
    # Add more scopes here as needed, e.g.:
    # {
    #   scope_name        = "write"
    #   scope_description = "Write access to the API"
    # }
  ]

  # -----------------------------------------------------------
  # Tags
  # -----------------------------------------------------------
  resource_tags = {
    env  = "dev"
    Iaac = "terraform"
  }
}
