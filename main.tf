# ─── VPC ─────────────────────────────────────────────────────────────────────

resource "tencentcloud_vpc" "main" {
  name       = "${var.cluster_name}-vpc"
  cidr_block = var.vpc_cidr
}

# ─── Subnets (one per AZ for HA) ─────────────────────────────────────────────

resource "tencentcloud_subnet" "az1" {
  name              = "${var.cluster_name}-subnet-1"
  vpc_id            = tencentcloud_vpc.main.id
  availability_zone = "eu-frankfurt-1"
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1) # e.g. 10.0.1.0/24
}

resource "tencentcloud_subnet" "az2" {
  name              = "${var.cluster_name}-subnet-2"
  vpc_id            = tencentcloud_vpc.main.id
  availability_zone = "eu-frankfurt-2"
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2) # e.g. 10.0.2.0/24
}

# ─── Security Group for worker nodes ─────────────────────────────────────────

resource "tencentcloud_security_group" "nodes" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for ${var.cluster_name} worker nodes"
}

resource "tencentcloud_security_group_rule_set" "nodes" {
  security_group_id = tencentcloud_security_group.nodes.id

  ingress {
    action      = "ACCEPT"
    cidr_block  = var.vpc_cidr
    protocol    = "ALL"
    port        = "ALL"
    description = "Allow all intra-VPC traffic"
  }

  egress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "ALL"
    port        = "ALL"
    description = "Allow all outbound traffic"
  }
}

# ─── TKE Managed Cluster ──────────────────────────────────────────────────────

resource "tencentcloud_kubernetes_cluster" "main" {
  cluster_name         = var.cluster_name
  cluster_version      = var.kubernetes_version
  cluster_deploy_type  = "MANAGED_CLUSTER"
  vpc_id               = tencentcloud_vpc.main.id
  cluster_cidr         = var.cluster_cidr
  service_cidr         = var.service_cidr

  # Private endpoint only — access the API server from within the VPC
  cluster_internet              = false
  cluster_intranet              = true
  cluster_intranet_subnet_id    = tencentcloud_subnet.az1.id
}

# ─── Node Pool ────────────────────────────────────────────────────────────────

resource "tencentcloud_kubernetes_node_pool" "main" {
  cluster_id       = tencentcloud_kubernetes_cluster.main.id
  name             = "${var.cluster_name}-pool"
  vpc_id           = tencentcloud_vpc.main.id
  subnet_ids       = [tencentcloud_subnet.az1.id, tencentcloud_subnet.az2.id]
  min_size         = var.node_min_count
  max_size         = var.node_max_count
  desired_capacity = var.node_desired_count

  auto_scaling_config {
    instance_type      = var.node_instance_type
    system_disk_type   = "CLOUD_PREMIUM"
    system_disk_size   = 50
    security_group_ids = [tencentcloud_security_group.nodes.id]
    password           = var.node_password
  }
}
