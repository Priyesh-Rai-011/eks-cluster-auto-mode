# ==============================================================
#  DEV EKS — infra/dev/eks/terragrunt.hcl
#
#  Account:  185863138492
#  Region:   ap-south-1
#  VPC:      vpc-04379b52e272b7163  (172.31.0.0/16)
#
#  Private subnets (all on private-rt → rtb-02d59d2328aed711e):
#    private-subnet-1 → subnet-0df7eccd47048315b  (ap-south-1a)
#    private-subnet-2 → subnet-0f885de2c43d51937  (ap-south-1b)
#    private-subnet-3 → subnet-0c3d8e81cd94a6f0f  (ap-south-1c)
# ==============================================================

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/eks"
}

# Force correct region — prevents any CLI region mismatch
generate "provider_override" {
  path      = "provider.tf"
  if_exists = "overwrite"
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

inputs = {

  create_ekscluster  = true
  region             = "ap-south-1"
  availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

  # -------------------------------------------------------
  #  VPC & SUBNETS — account 185863138492
  # -------------------------------------------------------
  aws_vpc_id = "vpc-04379b52e272b7163"

  private_app_subnets_ids = [
    "subnet-0df7eccd47048315b", # private-subnet-1 | ap-south-1a | 172.31.48.0/20
    "subnet-0f885de2c43d51937", # private-subnet-2 | ap-south-1b | 172.31.64.0/20
    "subnet-0c3d8e81cd94a6f0f", # private-subnet-3 | ap-south-1c | 172.31.80.0/20
  ]

  resource_tags = {
    env     = "dev"
    Iaac    = "terragrunt"
    project = "myapp"
    team    = "platform"
    account = "185863138492"
  }

  # -------------------------------------------------------
  #  EKS AUTO MODE CLUSTER MAP
  # -------------------------------------------------------
  eks_cluster = {
    "eks_cluster_dev" = {
      clustername             = "pmyapp-eks-dev"
      kubernetes_version      = "1.33"
      auto_mode_node_pools    = ["general-purpose", "system"]

      # Public + Private endpoint enabled so kubectl works from laptop
      endpoint_public_access  = true
      endpoint_private_access = true

      enable_logging        = true
      cluster_logging_types = ["api", "audit", "authenticator"]

      # VPC CIDR: 172.31.0.0/16
      sg_ingress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["172.31.0.0/16"]
          description = "Allow-allinternalVPCtraffic"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPSfromanywhereneededforpublickubectlaccess"
        }
      ]
    }
  }
}
