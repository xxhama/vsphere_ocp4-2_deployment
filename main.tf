resource "random_string" "cluster_id" {
  length  = 10
  special = false
  upper   = false
}

# SSH Key for VMs
resource "tls_private_key" "installkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_private_key" {
  content         = tls_private_key.installkey.private_key_pem
  filename        = "${path.root}/installer-files/artifacts/openshift_rsa"
  file_permission = 0600
}

resource "local_file" "write_public_key" {
  content         = tls_private_key.installkey.public_key_openssh
  filename        = "${path.root}/installer-files/artifacts/openshift_rsa.pub"
  file_permission = 0600
}

locals {
  cluster_id = var.cluster_name
  tags = merge(
  {
    "kubernetes.io_cluster.${local.cluster_id}" = "owned"
  }
  )
}

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

module "haproxy" {
  source                        = "./config_lb_server"
  vm_os_user                    = var.vm_os_user
  vm_os_password                = var.vm_os_password
  vm_os_private_key             = var.vm_os_private_key
  vm_ipv4_address               = var.vm_ipv4_address
}