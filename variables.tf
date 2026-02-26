variable "region" {
  description = "Tencent Cloud region"
  type        = string
  default     = "eu-frankfurt"
}

variable "secret_id" {
  description = "Tencent Cloud SecretId"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Tencent Cloud SecretKey"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the TKE cluster (also used to prefix related resources)"
  type        = string
  default     = "tke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the TKE cluster"
  type        = string
  default     = "1.32.2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_cidr" {
  description = "CIDR block for the pod network (must not overlap with VPC or service CIDR)"
  type        = string
  default     = "172.16.0.0/16"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services (must not overlap with VPC or cluster CIDR)"
  type        = string
  default     = "172.17.0.0/22"
}

variable "node_instance_type" {
  description = "CVM instance type for worker nodes"
  type        = string
  default     = "SA2.MEDIUM2"
}

variable "node_desired_count" {
  description = "Desired number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 5
}

variable "node_password" {
  description = "Login password for worker node CVM instances"
  type        = string
  sensitive   = true
}
