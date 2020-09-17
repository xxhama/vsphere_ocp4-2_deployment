provider "vsphere" {
  version = "< 1.16.0"
  allow_unverified_ssl = "true"
}

resource "random_string" "cluster_id" {
  length  = 10
  special = false
  upper   = false
}

data "external" "get_vcenter_details" {
  program = ["/bin/bash", "./scripts/get_vcenter_details.sh"]
}

locals {
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

resource "random_string" "random-dir" {
  length  = 8
  special = false
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
  vm_private_ssh_key                 = chomp(tls_private_key.installkey.private_key_pem)
  vm_public_ssh_key                  = chomp(tls_private_key.installkey.public_key_openssh)
  vm_ipv4_gateway                    = var.infranode_vm_ipv4_gateway
  vm_ipv4_address                    = var.infranode_ip
  vm_ipv4_prefix_length              = var.infranode_vm_ipv4_prefix_length
  vm_private_adapter_type            = var.vm_private_adapter_type
  vm_private_network_interface_label = var.vsphere_network
  vm_disk1_datastore                 = var.vsphere_datastore
  vm_dns_servers                     = var.vm_dns_servers
  vm_dns_suffixes                    = var.vm_dns_suffixes
  vm_clone_timeout                   = var.vm_clone_timeout
  random                             = random_string.random-dir.result
}

module "ignition" {
  dependsOn = [module.deployVM_infranode.dependsOn]
  source                        = "./ignition"
  cluster_name                  = var.clustername
  base_domain                   = var.vm_domain_name
  openshift_version             = var.openshift_version
  openshift_pull_secret         = var.pullsecret
  public_ssh_key                = chomp(tls_private_key.installkey.public_key_openssh)
  datacenter                    = var.vsphere_datacenter
  datastore                     = var.vsphere_datastore
  proxy_host                    = var.proxy_server
  vcenter_url                   = local.vcenter
  vsphere_password              = local.vcenterpassword
  vsphere_user                  = local.vcenteruser
  infra_ip                      = var.infranode_ip
  master_ips                    = var.master_ips
  worker_ips                    = var.worker_ips
  gateway                       = var.infranode_vm_ipv4_gateway
  dns                           = var.vm_dns_servers
  bootstrap_ip                  = var.bootstrap_ip
  network_prefix                = var.infranode_vm_ipv4_prefix_length
  no_proxies                    = var.no_proxies
  username                      = var.infranode_vm_os_user
  ssh_private_key               = chomp(tls_private_key.installkey.private_key_pem)
}
// Module config file server for ign
//

module "iso-creation"{
  dependsOn = [module.deployVM_infranode.dependsOn]

  source                        = "./create_iso"
  binaries                      = var.binaries
  bootstrap_ip                  = var.bootstrap_ip
  master_ips                    = var.master_ips
  worker_ips                    = var.worker_ips
  infranode_ip                  = var.infranode_ip
  username                      = var.infranode_vm_os_user
  ssh_private_key               = chomp(tls_private_key.installkey.private_key_pem)
  network_device                = var.vsphere_network
  ocp_cluster                   = var.clustername
  base_domain                   = var.vm_domain_name
  netmask                       = "${cidrnetmask("${var.infranode_vm_ipv4_gateway}/${var.infranode_vm_ipv4_prefix_length}")}"
  gateway                       = var.infranode_vm_ipv4_gateway
  openshift_nameservers         = var.vm_dns_servers

  vsphere_url                   = local.vcenter
  vsphere_username              = local.vcenteruser
  vsphere_allow_insecure        = "true"
  vsphere_image_datastore       = var.vsphere_image_datastore
  vsphere_image_datastore_path  = var.vsphere_image_datastore_path
  vsphere_password              = local.vcenterpassword
  vsphere_data_center           = var.vsphere_datacenter

}

module "ign_file_server" {
  dependsOn = [module.iso-creation.dependsOn]

  source = "./ign-file-server"
  infra_host                     = var.infranode_ip
  infra_private_key              = chomp(tls_private_key.installkey.private_key_pem)
  vm_os_user                     = var.infranode_vm_os_user
  bootstrap_ign                  = module.ignition.bootstrap_ignition
  master_ign                    = module.ignition.master_ignitions
  worker_ign                    = module.ignition.worker_ignitions
}


// Module Configure LB
// Download, Configure, Enable/Start HAProxy
// Input:
// 1. Master IPs
// 2. Worker IPs
// 3. Bootstrap IP
module "haproxy" {
  dependsOn = [module.ign_file_server.dependsOn]

  source                        = "./config_lb_server"
  vm_os_user                    = var.infranode_vm_os_user
  vm_os_password                = var.infranode_vm_os_password
  vm_os_private_key             = chomp(tls_private_key.installkey.private_key_pem)
  vm_ipv4_address               = var.infranode_ip
  bootstrap_ip                  = var.bootstrap_ip
  master_ips                    = var.master_ips
  worker_ips                    = var.worker_ips
}



// Module OCP Cluster
// Input:
// 1. master.ign
// 2. worker.ign
// 3. append-bootstrap.ign

module "ocp-deployment" {
  dependsOn = [module.haproxy.dependsOn]

  source                = "./ocp-deployment"
  master_ign            = module.ignition.master_ignitions
  worker_ign            = module.ignition.worker_ignitions
  append_ign            = module.ignition.append_ignition
  bootstrap_ip          = var.bootstrap_ip
  master_ips            = var.master_ips
  worker_ips            = var.worker_ips
  folder                = var.vm_folder
  rhcos_template_path   = var.ocp_vm_template
  vsphere_datacenter    = var.vsphere_datacenter
  vsphere_datastore     = var.vsphere_datastore
  vsphere_network       = var.vsphere_network
  vsphere_resource_pool = var.vsphere_resource_pool
  domain_name           = var.vm_domain_name
  clustername           = var.clustername
  iso_folder            = var.vsphere_image_datastore_path
  iso_datastore         = var.vsphere_image_datastore
}

// Check for cluster deployment success
module "cluster_deployment_complete" {
  source = "./cluster_deployment_complete"
  dependsOn = [module.ocp-deployment.finished]
  installer_path = module.ignition.installer_path
  username                      = var.infranode_vm_os_user
  ssh_private_key               = chomp(tls_private_key.installkey.private_key_pem)
  infra_host                    = var.infranode_ip
  bootstrap_ip                  = var.bootstrap_ip
}