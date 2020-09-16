// Basic cluster variables

variable "cluster_name" {
  type = string
}

variable "base_domain" {
  type = string
}

// Network settings

variable "gateway" {
  type = string
}

variable "dns" {
  type = list(string)
}

variable "proxy_host" {
  type = string
}

variable "network_prefix" {
  type = string
}

variable "no_proxies" {
  type = list(string)
}

// Node IPs
variable "master_ips" {
  type = list(string)
}

variable "worker_ips" {
  type = list(string)
}

variable "bootstrap_ip" {
  type = string
}

variable "infra_ip" {
  type = string
}

// OpenShift settings
variable "public_ssh_key" {
  type = string
}

variable "openshift_pull_secret" {
  type = string
}

variable "openshift_installer_url" {
  type    = string
  default = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp"
}

variable "openshift_version" {
  type = string
}


// vCenter Settings
variable "vcenter_url" {
  type = string
}

variable "vsphere_user" {
  type = string
}

variable "vsphere_password" {
  type = string
}

variable "datacenter" {
  type = string
}

variable "datastore" {
  type = string
}
