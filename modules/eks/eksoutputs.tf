# ==============================================================
#  EKS AUTO MODE — eksoutputs.tf
# ==============================================================

output "eks_cluster_names" {
  description = "Names of all EKS clusters"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.name }
}

output "eks_cluster_arns" {
  description = "ARNs of all EKS clusters"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.arn }
}

output "eks_cluster_endpoints" {
  description = "API server endpoints"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.endpoint }
}

output "eks_cluster_versions" {
  description = "Kubernetes versions"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.version }
}

output "eks_cluster_role_arns" {
  description = "Control plane IAM role ARNs"
  value       = { for k, v in aws_iam_role.ekscluster_role : k => v.arn }
}

output "eks_auto_node_role_arns" {
  description = "Auto Mode node IAM role ARNs"
  value       = { for k, v in aws_iam_role.eks_auto_node_role : k => v.arn }
}

output "eks_security_group_ids" {
  description = "Security group IDs"
  value       = { for k, v in aws_security_group.eks_sg : k => v.id }
}

output "eks_oidc_issuer_urls" {
  description = "OIDC issuer URLs — needed for IRSA per workload"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.identity[0].oidc[0].issuer }
}

output "eks_certificate_authority_data" {
  description = "Base64 CA data for kubeconfig"
  value       = { for k, v in aws_eks_cluster.eks_cluster : k => v.certificate_authority[0].data }
  sensitive   = true
}
