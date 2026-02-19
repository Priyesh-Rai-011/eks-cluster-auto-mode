# ==============================================================
#  env.hcl
#  Location: infra/env.hcl
# ==============================================================

locals {
  aws_region     = "ap-south-1"
  aws_account_id = "185863138492"   # ← CORRECT account
  project_name   = "myapp"
  environment    = "dev"
}
