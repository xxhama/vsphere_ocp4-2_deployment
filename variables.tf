variable "base_domain" {
  type = string
}

variable "openshift_version" {
  type    = string
  default = "4.3.26"
}

variable "master_count" {
  type = string
  default = 3
}

variable "cluster_name" {
  type = string
}

variable "vsphere_network" {
  type = string
}

variable "openshift_cluster_network_cidr" {
  type    = string
  default = "10.128.0.0/14"
}

variable "openshift_cluster_network_host_prefix" {
  type    = string
  default = 23
}
variable "machine_v4_cidrs" {
  type = list(string)
  default = [
    "10.0.0.0/16"
  ]
}

variable "machine_v6_cidrs" {
  type    = list(string)
  default = []
}

variable "openshift_service_network_cidr" {
  type    = string
  default = "172.30.0.0/16"
}

variable "openshift_pull_secret" {}

variable "worker_count" {}

### vSphere information

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_resource_pool" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "proxy_host" {
  type        = string
}

### Infranode information 
variable "infranode_hostname" {
  type = string
}

variable "infranode_ip" {
  type = string
}

variable "infranode_vm_template" {
  type = string
}

variable "ocp_vm_template" {
  type = string
}

variable "vm_private_ssh_key" {
}

variable "vm_public_ssh_key" {
}

variable "infranode_vm_os_user" {
  type = string
}

variable "infranode_vm_os_password" {
  type = string
}

variable "infranode_vm_ipv4_gateway" {
  type = string
}

variable "infranode_vm_ipv4_prefix_length" {
  type = string
}

variable "infranode_vm_disk1_datastore" {
  type = string
}

variable "bootstrap_ip" {
  type = string
}

variable "master_ips" {
  type    = list(string)
}

variable "worker_ips" {
  type    = list(string)
}

variable "vm_folder" {
  type = string
}