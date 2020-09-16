resource "null_resource" "dependsOn" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

resource "null_resource" "check_deployment" {
  depends_on = [null_resource.dependsOn]
  provisioner "local-exec" {
    command = "${var.installer_path}/openshift-install --dir=${var.installer_path} wait-for install-complete"
  }
}

resource "null_resource" "approve_csr" {
  depends_on = [
    null_resource.check_deployment
  ]

  connection {
    host = var.infra_host
    user = var.username
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "for i in {1 3 5 10}; do oc get csr -o name | xargs oc adm certificate approve; sleep 1m; done",
    ]
  }
}