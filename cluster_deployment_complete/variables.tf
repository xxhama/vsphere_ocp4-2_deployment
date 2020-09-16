variable "installer_path" {
  type = string
}

variable "dependsOn" {}

variable "infra_host" {
  type = string
  default = "172.18.8.240"
}
variable "ssh_private_key" {
  type = string
}
variable "username" {
  type        = string
  description = "User for the Operating System User to access virtual machine"
}