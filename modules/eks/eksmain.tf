# ==============================================================
#  EKS AUTO MODE CLUSTER — eksmain.tf
#  Account: 185863138492 | Region: ap-south-1
#  Auto Mode: AWS manages compute, networking, storage, LB
# ==============================================================

terraform {
  # Local state — no backend
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs_in_use   = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  region_parts = split("-", var.region)
  region_short = format("%s%s%s",
    lower(substr(local.region_parts[0], 0, 1)),
    lower(substr(local.region_parts[1], 0, 1)),
    lower(substr(local.region_parts[2], 0, 1))
  )
  account_id = data.aws_caller_identity.current.account_id
}

# ==============================================================
#  EKS AUTO MODE CLUSTER
# ==============================================================
resource "aws_eks_cluster" "eks_cluster" {
  for_each = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.AmazonEKSNetworkingPolicy,
    aws_security_group.eks_sg,
  ]

  name     = each.value.clustername
  role_arn = aws_iam_role.ekscluster_role[each.key].arn
  version  = each.value.kubernetes_version

  # REQUIRED for EKS Auto Mode — must be false
  bootstrap_self_managed_addons = false

  # REQUIRED for EKS Auto Mode — must be API or API_AND_CONFIG_MAP
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  # Auto Mode: Compute — AWS provisions nodes on demand
#   compute_config {
#   enabled       = false
#   node_pools    = ["general-purpose", "system"]
#   node_role_arn = aws_iam_role.eks_auto_node_role[each.key].arn
# }
# storage_config {
#   block_storage {
#     enabled = false
#   }
# }
# kubernetes_network_config {
#   elastic_load_balancing {
#     enabled = false
#   }
# }


compute_config {
  enabled       = true
  node_pools    = each.value.auto_mode_node_pools
  node_role_arn = aws_iam_role.eks_auto_node_role[each.key].arn
}
storage_config {
  block_storage { enabled = true }
}
kubernetes_network_config {
  elastic_load_balancing { enabled = true }
}


  #================================================================

  vpc_config {
    subnet_ids              = var.private_app_subnets_ids
    endpoint_public_access  = each.value.endpoint_public_access
    endpoint_private_access = each.value.endpoint_private_access
    security_group_ids      = [aws_security_group.eks_sg[each.key].id]
  }

  enabled_cluster_log_types = each.value.enable_logging ? each.value.cluster_logging_types : []

  tags = merge(var.resource_tags, {
    Name = each.value.clustername
  })
}

# ==============================================================
#  IAM — CONTROL PLANE ROLE
# ==============================================================
resource "aws_iam_role" "ekscluster_role" {
  for_each    = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  name_prefix = "eks-cluster-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = merge(var.resource_tags, {
    Name = "eks-cluster-role-${each.value.clustername}"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSComputePolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSBlockStoragePolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSLoadBalancingPolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSNetworkingPolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.ekscluster_role[each.key].name
}

# ==============================================================
#  IAM — AUTO MODE NODE ROLE
# ==============================================================
resource "aws_iam_role" "eks_auto_node_role" {
  for_each    = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  name_prefix = "eks-auto-node-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    },
    {
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.resource_tags, {
    Name = "eks-auto-node-role-${each.value.clustername}"
  })
}

resource "aws_iam_role_policy_attachment" "AutoNode_EKSWorkerNodeMinimalPolicy" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AutoNode_EC2ContainerRegistryPullOnly" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AutoNode_SSMManagedInstanceCore" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AutoNode_SESFullAccess" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AutoNode_S3FullAccess" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

resource "aws_iam_role_policy_attachment" "AutoNode_SecretsManagerReadWrite" {
  for_each   = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.eks_auto_node_role[each.key].name
}

# ==============================================================
#  SECURITY GROUP
# ==============================================================
resource "aws_security_group" "eks_sg" {
  for_each    = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
  name        = "${each.value.clustername}-sg2"
  description = "Security group for EKS cluster ${each.value.clustername}"
  vpc_id      = var.aws_vpc_id

  dynamic "ingress" {
    for_each = each.value.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", null)
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.resource_tags, {
    Name = "${each.value.clustername}-sg"
  })
}

# ==============================================================
#  EKS ADD-ONS
#  Auto Mode manages: vpc-cni, kube-proxy, coredns, ebs-csi
#  Only metrics-server needs explicit install.
# ==============================================================
# resource "aws_eks_addon" "metrics_server" {
#   for_each                    = var.create_ekscluster == true ? { for k, v in var.eks_cluster : k => v } : {}
#   cluster_name                = each.value.clustername
#   addon_name                  = "metrics-server"
#   addon_version               = "v0.7.2-eksbuild.1"
#   resolve_conflicts_on_update = "PRESERVE"
#   # depends_on                = [aws_eks_cluster.eks_cluster]
#   depends_on                  = [aws_eks_cluster.eks_cluster,aws_eks_access_entry.node_access]
#   tags                        = var.resource_tags
# }



# resource "aws_eks_access_entry" "node_access" {
#   for_each      = var.create_ekscluster ? var.eks_cluster : {}
#   cluster_name  = aws_eks_cluster.eks_cluster[each.key].name
#   principal_arn = aws_iam_role.eks_auto_node_role[each.key].arn
#   type          = "STANDARD"
# }
# resource "aws_eks_access_entry" "node_access" {
#   for_each      = var.create_ekscluster ? var.eks_cluster : {}
#   cluster_name  = aws_eks_cluster.eks_cluster[each.key].name
#   principal_arn = aws_iam_role.eks_auto_node_role[each.key].arn
#   type          = "EC2_LINUX" # Change from EC2_LINUX to STANDARD
# }