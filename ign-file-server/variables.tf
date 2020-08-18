variable "infra_host" {
  type = string
  default = "172.18.8.240"
}
variable "infra_private_key" {
  type = string
}

variable "ign_path" {
  type = string
}

variable "dependsOn" {
  default     = "true"
  description = "Boolean for dependency"
}