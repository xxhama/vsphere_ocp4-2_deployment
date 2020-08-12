resource "null_resource" "copy_ign_file" {

  connection {
    type                = "ssh"
    private_key         = var.infra_private_key
    host                = var.infra_host
  }

  provisioner "file" {
    source = "./installer-files/bootstrap.ign"
    destination = "/tmp/ignition"
  }
}