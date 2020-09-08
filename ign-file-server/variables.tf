variable "infra_host" {
  type = string
  default = "172.18.8.240"
}
variable "infra_private_key" {
  type = string
}
variable "vm_os_user" {
  type        = string
  description = "User for the Operating System User to access virtual machine"
}
variable "bootstrap_ign" {}
variable "master_ign" {}
variable "worker_ign" {}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}