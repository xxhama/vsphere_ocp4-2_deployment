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
      "ssh -o \"StrictHostKeyChecking no\" ${var.bootstrap_ip}",
      "until ssh core@${var.bootstrap_ip} 'journalctl -b  -u bootkube.service' |grep -o 'bootkube.service complete';do echo 'waiting for bootstrap to complete'; sleep 1m ;done",
      "chmod +x /usr/local/bin/kubectl",
      "chmod +x /usr/local/bin/oc",
      "export KUBECONFIG=/opt/kubeconfig",
      "for i in {1 3 5 10}; do oc get csr -o name | xargs oc adm certificate approve; sleep 1m; done",

    ]
  }
}

resource "null_resource" "check_deployment" {
  depends_on = [null_resource.approve_csr]
  provisioner "local-exec" {
    command = "${var.installer_path}/openshift-install --dir=${var.installer_path} wait-for install-complete"
  }
}
