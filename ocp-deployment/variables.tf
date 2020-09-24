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

// Ignition Files
variable "master_ign" {}
variable "worker_ign" {}
variable "append_ign" {}

// Host Names
variable "domain_name" {}
variable "clustername" {}

// ISO Info
variable "iso_folder" {}
variable "iso_datastore" {}

// Data objects
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore 
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "iso_datastore" {
  name = var.iso_datastore
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
  datacenter_id = data.vsphere_datacenter.dc.id
  name = "rhcos-template"
}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}