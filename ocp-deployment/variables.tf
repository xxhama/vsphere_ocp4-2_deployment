// vSphere Variable
variable "vsphere_datacenter" {}
variable "vsphere_datastore" {}
variable "vsphere_resource_pool" {}
variable "vsphere_network" {}
variable "folder" {}

// OCP Variables
variable "bootstrap_ip" {}
variable "master_ips" {}
variable "worker_ips" {}
variable "rhcos_template_path" {}

// Ignition Files
variable "master_ign" {}
variable "worker_ign" {}
variable "append_ign" {}

// Host Names
variable domain_name {}

// Data objects
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "master-worker-template" {
  name          = var.rhcos_template_path
  datacenter_id = data.vsphere_datacenter.dc.id
}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}