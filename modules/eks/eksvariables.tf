# ==============================================================
#  EKS AUTO MODE — eksvariables.tf
#  Account: 185863138492 | Region: ap-south-1
# ==============================================================

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "availability_zones" {
  description = "Override AZs. Empty = all available in region."
  type        = list(string)
  default     = []
}

variable "resource_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    env     = "dev"
    Iaac    = "terragrunt"
    project = "myapp"
    account = "185863138492"
  }
}

variable "aws_vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_app_subnets_ids" {
  description = "Private subnet IDs for EKS control plane and Auto Mode nodes"
  type        = list(string)
}

variable "private_subnets_ids" {
  type    = list(string)
  default = []
}

variable "private_db_subnets_ids" {
  type    = list(string)
  default = []
}

variable "create_ekscluster" {
  description = "Set true to deploy EKS resources"
  type        = bool
  default     = false
}

variable "eks_cluster" {
  description = "Map of EKS Auto Mode cluster configurations"
  type = map(object({
    clustername             = string
    kubernetes_version      = string
    auto_mode_node_pools    = list(string)
    endpoint_public_access  = bool
    endpoint_private_access = bool
    enable_logging          = bool
    cluster_logging_types   = list(string)
    sg_ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = optional(string)
    }))
  }))

  default = {
    "eks_cluster_dev" = {
      clustername             = "pmyapp-eks-dev"
      kubernetes_version      = "1.33"
      auto_mode_node_pools    = ["general-purpose", "system"]
      endpoint_public_access  = false
      endpoint_private_access = true
      enable_logging          = true
      cluster_logging_types   = ["api", "audit", "authenticator"]
      sg_ingress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["172.31.0.0/16"]
          description = "Allow all internal VPC traffic"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["172.31.0.0/16"]
          description = "HTTPS from VPC only"
        }
      ]
    }
  }
}
