# ==============================================================
#  PROD EKS — infra/prod/eks/terragrunt.hcl
# ==============================================================

include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  aws_region  = local.env_vars.locals.aws_region
}

terraform {
  source = "../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                  = "vpc-00000000000000000"
    private_app_subnets_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  create_ekscluster       = true
  aws_vpc_id              = dependency.vpc.outputs.vpc_id
  private_app_subnets_ids = dependency.vpc.outputs.private_app_subnets_ids
  region                  = local.aws_region
  availability_zones      = []

  resource_tags = {
    env     = local.environment
    Iaac    = "terragrunt"
    project = local.env_vars.locals.project_name
    team    = "platform"
  }

  eks_cluster = {
    "eks_cluster_prod" = {
      clustername            = "myapp-eks-${local.environment}"
      kubernetes_version     = "1.33"
      auto_mode_node_pools   = ["general-purpose", "system"]
      endpoint_public_access  = false
      endpoint_private_access = true
      enable_logging          = true
      # Full logging enabled in prod
      cluster_logging_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

      sg_ingress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["10.0.32.0/19"]
          description = "Allow all internal VPC traffic"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "HTTPS from private network only"
        }
      ]
    }
  }
}
