resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

resource "null_resource" "approve_csr" {
  depends_on = [
    null_resource.dependency
  ]
  connection {
    host = var.infra_host
    user = var.username
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/local/bin/kubectl",
      "chmod +x /usr/local/bin/oc",
      "export KUBECONFIG=/opt/kubeconfig",
      "for i in {1 4 8 12}; do oc get csr -o name | xargs oc adm certificate approve; sleep 240; done",

    ]
  }
}

resource "null_resource" "check_deployment" {
  depends_on = [null_resource.approve_csr]
  provisioner "local-exec" {
    command = "${var.installer_path}/openshift-install --dir=${var.installer_path} wait-for install-complete"
  }
}
