# ==============================================================
#  ROOT terragrunt.hcl
#  Location: infra/terragrunt.hcl
#  Account:  185863138492
#  Region:   ap-south-1
# ==============================================================

locals {
  region     = "ap-south-1"
  account_id = "185863138492"
}

# -------------------------------------------------------
# Remote state — one state file per module per env
# -------------------------------------------------------
remote_state {
  backend = "s3"
  config = {
    bucket                = "terraform-state-${local.account_id}-${local.region}"
    key                   = "${path_relative_to_include()}/terraform.tfstate"
    region                = local.region
    encrypt               = true
    disable_bucket_update = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# -------------------------------------------------------
# AWS Provider
# -------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Iaac   = "terraform"
      Region = "${local.region}"
    }
  }
}
EOF
}