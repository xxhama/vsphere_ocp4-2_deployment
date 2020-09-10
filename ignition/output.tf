output "append_ignition" {
  value = data.local_file.append_ign.content
}

output "master_ignitions" {
  value = data.local_file.master_igns
}

output "worker_ignitions" {
  value = data.local_file.worker_igns
}

output "bootstrap_ignition" {
  value = data.local_file.bootstrap_ign.content
}

output "kubeadmin_password" {
  value = data.local_file.kubeadmin_password.content
}

output "kubeconfig" {
  value = data.local_file.kubeconfig.content_base64
}

output "installer_path" {
  value = local.installer_workspace
}