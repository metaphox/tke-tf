output "cluster_id" {
  description = "TKE cluster ID"
  value       = tencentcloud_kubernetes_cluster.main.id
}

output "cluster_endpoint" {
  description = "Private (intranet) API server endpoint"
  value       = tencentcloud_kubernetes_cluster.main.cluster_intranet_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster (intranet access)"
  value       = tencentcloud_kubernetes_cluster.main.kube_config_intranet
  sensitive   = true
}
