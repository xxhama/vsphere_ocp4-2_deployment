provider "vsphere" {}

resource "random_string" "cluster_id" {
  length  = 10
  special = false
  upper   = false
}

locals {
  cluster_id = var.cluster_name
}

// Module Infra node
// Inputs
// 1. vSphere Cluster
// 2. DataCenter
// 3. Resource Pool
// 4. infra node ip
// 5. folder
// 6. proxy server:port
// 7. vSphere Network
// 8. DNS?
// Outputs
//

module "ignition" {
  source                        = "./ignition"
  base_domain                   = var.base_domain
  openshift_version             = var.openshift_version
  master_count                  = var.master_count
  cluster_name                  = var.cluster_name
  cluster_network_cidr          = var.openshift_cluster_network_cidr
  cluster_network_host_prefix   = var.openshift_cluster_network_host_prefix
  machine_cidr                  = var.machine_v4_cidrs[0]
  service_network_cidr          = var.openshift_service_network_cidr
  openshift_pull_secret         = var.openshift_pull_secret
  public_ssh_key                = chomp(tls_private_key.installkey.public_key_openssh)
  cluster_id                    = local.cluster_id
  node_count                    = var.worker_count
}

// Module config file server for ign
//

// Module Configure LB
// Download, Configure, Enable/Start HAProxy
// Input:
// 1. Master IPs
// 2. Worker IPs
// 3. Bootstrap IP

// Module OCP Cluster
// Input:
// 1. master.ign
// 2. worker.ign
// 3. append-bootstrap.ign

// Module Complete Check