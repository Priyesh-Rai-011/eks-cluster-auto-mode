# ==============================================================
#  ROOT terragrunt.hcl
#  Location: infra/terragrunt.hcl
#  Account:  185863138492
#  Region:   ap-south-1
# ==============================================================

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
EOF
}
