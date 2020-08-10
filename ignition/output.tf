output "bootstrap_ignition" {
  value = data.ignition_config.append_ign.rendered
}

output "master_ignition" {
  value = data.ignition_config.master_ign.rendered
}

output "worker_ignition" {
  value = data.ignition_config.worker_ign.rendered
}