output "dependsOn" {
  value       = null_resource.images_created.id
  description = "Output Parameter set when the module execution is completed"
}