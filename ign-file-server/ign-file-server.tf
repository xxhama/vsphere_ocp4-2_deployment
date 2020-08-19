resource "null_resource" "copy_ign_file" {

  connection {
    type                = "ssh"
    private_key         = var.infra_private_key
    user                = var.vm_os_user
    host                = var.infra_host
  }

  provisioner "file" {
    content = var.bootstrap_ign
    destination = "/tmp/ignition"
  }
  

  provisioner "remote-exec" {
    inline = [
      "systemctl stop firewalld",
      "yum install httpd -y",
      "sed -i -e "\"s/Listen 80/Listen 8080/"\" /etc/httpd/conf/httpd.conf",
      "systemctl start httpd",
      "ln -s /tmp/ignition /var/www/html"
    ]
  }
}

resource "null_resource" "web_server_created" {
  depends_on = [
    null_resource.copy_ign_file
  ]
  provisioner "local-exec" {
    command = "echo 'Web server created'"
  }
}