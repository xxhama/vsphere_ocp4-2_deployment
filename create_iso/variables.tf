variable "dependson" {
  type    = list(string)
  default = []
}

variable "binaries" {
  type = map(string)
}

variable "bootstrap_ip" {
  type = string
}

variable "master_ips" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "infranode_ip"{
  type = string
}

variable "username"{
  type = string
}

variable "ssh_private_key"{
  type = string
}

variable "netmask"{
  type = string
}
variable "openshift_nameservers" {
  type = list
}

variable "gateway"{
  type = string
}

variable "ocp_cluster"{
  type = string
}

variable "base_domain" {
  type = string
}

variable "network_device" {
  type = string
}

variable "vsphere_url"{
  type = string
}

variable "vsphere_username" {
  type = string
}

variable "vsphere_password" {
  type = string
}

variable "vsphere_allow_insecure" {
  type = string
}

variable "vsphere_image_datastore" {
  type = string
}

variable "vsphere_image_datastore_path" {
  type = string
}
