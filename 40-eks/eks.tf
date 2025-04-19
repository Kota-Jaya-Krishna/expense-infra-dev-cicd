# EKS Cluster Name
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

# EKS Cluster Endpoint
output "cluster_endpoint" {
  description = "The endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}

# EKS Cluster CA Data (Certificate Authority)
output "cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}
