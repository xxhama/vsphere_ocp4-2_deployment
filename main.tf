provider "vsphere" {}

resource "random_string" "cluster_id" {
  length  = 10
  special = false
  upper   = false
}

locals {
  cluster_id = var.cluster_name
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

module "deployVM_infranode" {
  source = "./infra_vm_deployment"
  
  #######
  vsphere_datacenter                 = var.vsphere_datacenter
  vsphere_resource_pool              = var.vsphere_resource_pool
  vm_name                            = var.infranode_hostname
  vm_template                        = var.infranode_vm_template
  vm_os_password                     = var.infranode_vm_os_password
  vm_os_user                         = var.infranode_vm_os_user
  vm_domain                          = var.vm_domain_name
  vm_folder                          = var.vm_folder
  proxy_server                       = var.proxy_server
  vm_private_ssh_key                 = tls_private_key.generate.private_key_pem 
  vm_public_ssh_key                  = tls_private_key.generate.public_key_openssh 
  vm_private_network_interface_label = var.vm_private_network_interface_label
  vm_ipv4_gateway                    = var.infranode_vm_ipv4_gateway
  vm_ipv4_address                    = var.infranode_ip
  vm_ipv4_prefix_length              = var.infranode_vm_ipv4_prefix_length
  vm_private_adapter_type            = var.vm_private_adapter_type
  vm_disk1_datastore                 = var.infranode_vm_disk1_datastore
  vm_dns_servers                     = var.vm_dns_servers
  vm_dns_suffixes                    = var.vm_dns_suffixes
  vm_clone_timeout                   = var.vm_clone_timeout
  random                             = random_string.random-dir.result

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