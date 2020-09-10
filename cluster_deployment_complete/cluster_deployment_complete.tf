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