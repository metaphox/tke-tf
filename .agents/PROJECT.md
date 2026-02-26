# tke-tf — Project Summary

## Overview

This project is a **Terraform configuration** that provisions a fully managed **Tencent Kubernetes Engine (TKE)** cluster on Tencent Cloud. It creates all required networking infrastructure, security rules, the Kubernetes cluster itself, and an autoscaling node pool — all in a single `terraform apply`.

## Technology Stack

| Layer          | Technology                                                  |
| -------------- | ----------------------------------------------------------- |
| IaC            | Terraform ≥ 1.5.0                                           |
| Cloud Provider | Tencent Cloud (`tencentcloudstack/tencentcloud` ~> 1.82.0)  |
| Default Region | `eu-frankfurt`                                               |
| Kubernetes     | TKE Managed Cluster, default version `1.30.0`               |

## File Structure

```
.
├── main.tf          # All resource definitions (VPC, subnets, SG, TKE cluster, node pool)
├── variables.tf     # Input variables with defaults and descriptions
├── outputs.tf       # Outputs: cluster ID, private endpoint, kubeconfig
├── versions.tf      # Terraform & provider version constraints + provider config
├── README.md        # Placeholder readme
└── .gitignore       # Ignores .terraform/, *.tfstate*, terraform.tfvars, crash.log
```

## Resources Created (`main.tf`)

The resources are defined in the following order — each subsequent resource depends on the ones above it:

1. **`tencentcloud_vpc.main`** — VPC with a configurable CIDR (default `10.0.0.0/16`).
2. **`tencentcloud_subnet.az1`** — Subnet in `eu-frankfurt-1`, auto-calculated from VPC CIDR (`/24`).
3. **`tencentcloud_subnet.az2`** — Subnet in `eu-frankfurt-2`, auto-calculated from VPC CIDR (`/24`).
4. **`tencentcloud_security_group.nodes`** — Security group for worker nodes.
5. **`tencentcloud_security_group_rule_set.nodes`** — Rules: allow all intra-VPC ingress, allow all egress.
6. **`tencentcloud_kubernetes_cluster.main`** — TKE managed cluster with **private endpoint only** (no public API access).
7. **`tencentcloud_kubernetes_node_pool.main`** — Autoscaling node pool spanning both AZs, with configurable min/max/desired counts.

### Architecture Diagram

```
VPC (10.0.0.0/16)
├── Subnet AZ1 (eu-frankfurt-1, 10.0.1.0/24)
├── Subnet AZ2 (eu-frankfurt-2, 10.0.2.0/24)
├── Security Group (intra-VPC allow all, egress allow all)
├── TKE Managed Cluster (private endpoint on Subnet AZ1)
│   └── Node Pool (spans AZ1 + AZ2, autoscaling 2–5 nodes)
```

## Input Variables (`variables.tf`)

| Variable              | Type     | Default           | Sensitive | Description                                      |
| --------------------- | -------- | ----------------- | --------- | ------------------------------------------------ |
| `region`              | `string` | `eu-frankfurt`    | No        | Tencent Cloud region                             |
| `secret_id`           | `string` | —                 | **Yes**   | Tencent Cloud SecretId                           |
| `secret_key`          | `string` | —                 | **Yes**   | Tencent Cloud SecretKey                          |
| `cluster_name`        | `string` | `tke-cluster`     | No        | Name prefix for all resources                    |
| `kubernetes_version`  | `string` | `1.30.0`          | No        | Kubernetes version                               |
| `vpc_cidr`            | `string` | `10.0.0.0/16`     | No        | VPC CIDR block                                   |
| `cluster_cidr`        | `string` | `172.16.0.0/16`   | No        | Pod network CIDR (must not overlap VPC/service)  |
| `service_cidr`        | `string` | `172.17.0.0/22`   | No        | Service CIDR (must not overlap VPC/cluster)      |
| `node_instance_type`  | `string` | `S5.MEDIUM4`      | No        | CVM instance type for workers                    |
| `node_desired_count`  | `number` | `2`               | No        | Desired node count                               |
| `node_min_count`      | `number` | `2`               | No        | Minimum node count                               |
| `node_max_count`      | `number` | `5`               | No        | Maximum node count                               |
| `node_password`       | `string` | —                 | **Yes**   | Login password for worker node CVMs              |

> [!IMPORTANT]
> Three variables have **no defaults** and must always be provided: `secret_id`, `secret_key`, and `node_password`. Supply them via `terraform.tfvars` (gitignored) or environment variables.

## Outputs (`outputs.tf`)

| Output             | Description                             | Sensitive |
| ------------------ | --------------------------------------- | --------- |
| `cluster_id`       | TKE cluster ID                          | No        |
| `cluster_endpoint` | Private (intranet) API server endpoint  | No        |
| `kubeconfig`       | Kubeconfig for intranet cluster access  | **Yes**   |

## Usage

```bash
# 1. Initialize
terraform init

# 2. Review the plan
terraform plan -var-file="terraform.tfvars"

# 3. Apply
terraform apply -var-file="terraform.tfvars"

# 4. Destroy (when done)
terraform destroy -var-file="terraform.tfvars"
```

## Key Design Decisions

- **Private-only API server** — `cluster_internet = false`, `cluster_intranet = true`. The Kubernetes API is reachable only from within the VPC.
- **Multi-AZ HA** — Worker nodes are spread across two availability zones (`eu-frankfurt-1` and `eu-frankfurt-2`).
- **Autoscaling** — The node pool uses Tencent Cloud autoscaling with configurable min/max/desired counts (defaults: 2/5/2).
- **Simple security** — The security group allows all intra-VPC traffic and all egress; tighten for production use.
- **50 GB CLOUD_PREMIUM system disk** on each worker node.

## Conventions for Agents

- All resource names are prefixed with `var.cluster_name` for easy identification.
- Subnet CIDRs are derived from `var.vpc_cidr` using `cidrsubnet()` — changing the VPC CIDR automatically adjusts subnet CIDRs.
- Sensitive values (`secret_id`, `secret_key`, `node_password`, `kubeconfig`) are marked `sensitive = true` in Terraform.
- The `.gitignore` excludes `terraform.tfvars`, `.terraform/`, state files, and crash logs.
