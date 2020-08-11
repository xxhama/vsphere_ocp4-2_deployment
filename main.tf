provider "vsphere" {}

resource "random_string" "cluster_id" {
  length  = 10
  special = false
  upper   = false
}

data "external" "get_vcenter_details" {
  program = ["/bin/bash", "./scripts/get_vcenter_details.sh"]
}

locals {
  cluster_id = var.cluster_name
  vcenter         = data.external.get_vcenter_details.result["vcenter"]
  vcenteruser     = data.external.get_vcenter_details.result["vcenteruser"]
  vcenterpassword = data.external.get_vcenter_details.result["vcenterpassword"]
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
  proxy_server                       = var.proxy_host
  vm_private_ssh_key                 = chomp(tls_private_key.nstallkey.private_key_pem)
  vm_public_ssh_key                  = chomp(tls_private_key.installkey.public_key_openssh) 
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
  service_network_cidr          = var.openshift_service_network_cidr
  openshift_pull_secret         = var.openshift_pull_secret
  public_ssh_key                = chomp(tls_private_key.installkey.public_key_openssh)
  cluster_id                    = local.cluster_id
  node_count                    = var.worker_count
  datacenter                    = var.vsphere_datacenter
  datastore                     = var.vsphere_datacenter
  proxy_host                    = var.proxy_host 
  vcenter_url                   = local.vcenter
  vsphere_password              = local.vcenterpassword
  vsphere_user                  = local.vcenteruser
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
module "ocp-deployment" {
  source = "./ocp-deployment"
  master_ign            = module.ignition.master_ignition
  worker_ign            = module.ignition.worker_ignition
  append_ign            = module.ignition.bootstrap_ignition
  masters_count         = var.master_count
  workers_count         = var.worker_count
  bootstrap_ip          = var.bootstrap_ip
  master_ips            = var.master_ips
  worker_ips            = var.worker_ips
  folder                = var.vm_folder
  rhcos_template_path   = var.ocp_vm_template
  vsphere_datacenter    = var.vsphere_datacenter
  vsphere_datastore     = var.infranode_vm_disk1_datastore
  vsphere_network       = var.vsphere_network
  vsphere_resource_pool = var.vsphere_resource_pool
}

// Module Complete Check

module "haproxy" {
  source                        = "./config_lb_server"
  vm_os_user                    = var.vm_os_user
  vm_os_password                = var.vm_os_password
  vm_os_private_key             = var.vm_os_private_key
  vm_ipv4_address               = var.vm_ipv4_address
}
