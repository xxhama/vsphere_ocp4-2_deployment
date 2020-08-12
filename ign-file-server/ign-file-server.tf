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

  provisioner "remote-exec" {
    inline = [
      "systemctl stop firewalld",
      "yum install httpd -y",
      "systemctl start httpd",
      "ln -s /tmp/ignition /var/www/html"
    ]
  }
}