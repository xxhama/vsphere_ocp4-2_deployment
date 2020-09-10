output "kubeadmin_password" {
  value = module.ignition.kubeadmin_password
}

output "kubeconfig" {
  value = module.ignition.kubeconfig
}

output "cluster_url" {
  value = "https://console-openshift-console.apps.${var.clustername}.${var.vm_domain_name}/"
}