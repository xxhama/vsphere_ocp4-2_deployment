output "dependsOn" {
  value       = null_resource.web_server_created.id
  description = "Output Parameter set when the module execution is completed"
}