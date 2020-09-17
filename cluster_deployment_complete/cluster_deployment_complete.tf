resource "null_resource" "dependsOn" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

resource "null_resource" "approve_csr" {

  connection {
    host = var.infra_host
    user = var.username
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "ssh core@${var.bootstrap_ip}",
      "until journalctl -b  -u bootkube.service |grep -o 'bootkube.service complete';do echo 'waiting for bootstrap to complete'; sleep 1m ;done",
      "exit",
      "for i in {1 3 5 10}; do oc get csr -o name | xargs oc adm certificate approve; sleep 1m; done",
    ]
  }
}

