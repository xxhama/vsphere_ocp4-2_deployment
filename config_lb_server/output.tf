output "dependsOn" {
  value       = null_resource.lb_server_create.id
  description = "Output Parameter set when the module execution is completed"
}
