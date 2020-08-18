variable "infra_host" {
  type = string
  default = "172.18.8.240"
}
variable "infra_private_key" {
  type = string
}

variable "bootstrap_ign" {}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}