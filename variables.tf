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


