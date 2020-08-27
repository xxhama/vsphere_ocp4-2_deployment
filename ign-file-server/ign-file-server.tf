resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

resource "null_resource" "configure_apache_server" {

  depends_on = [
    null_resource.dependency
  ]

  connection {
    type = "ssh"
    private_key = var.infra_private_key
    user = var.vm_os_user
    host = var.infra_host
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl stop firewalld",
      "yum update -y",
      "yum install httpd -y",
      "sed -i -e \"s/Listen 80/Listen 8080/\" /etc/httpd/conf/httpd.conf",
      "systemctl start httpd",
      "mkdir -p /opt/igns"
    ]
  }
}

resource "null_resource" "copy_bootstrap-ign" {
  depends_on = [null_resource.configure_apache_server]

  connection {
    type                = "ssh"
    private_key         = var.infra_private_key
    user                = var.vm_os_user
    host                = var.infra_host
  }

  provisioner "file" {
    content = var.bootstrap_ign
    destination = "/opt/igns/bootstrap.ign"
  }
}

resource "null_resource" "copy_worker-igns" {
  depends_on = [null_resource.configure_apache_server]
  count = length(var.worker_igns)

  connection {
    type                = "ssh"
    private_key         = var.infra_private_key
    user                = var.vm_os_user
    host                = var.infra_host
  }

  provisioner "file" {
    content = var.worker_igns[count.index].content
    destination = "/opt/igns/worker${count.index}.ign"
  }
}

resource "null_resource" "copy_master-igns" {
  depends_on = [null_resource.configure_apache_server]
  count = length(var.master_igns)

  connection {
    type                = "ssh"
    private_key         = var.infra_private_key
    user                = var.vm_os_user
    host                = var.infra_host
  }

  provisioner "file" {
    content = var.master_igns[count.index].content
    destination = "/opt/igns/master${count.index}.ign"
  }
}

resource "null_resource" "expose_ign_files" {
  depends_on = [
    null_resource.configure_apache_server,
    null_resource.copy_bootstrap-ign,
    null_resource.copy_master-igns,
    null_resource.copy_worker-igns
  ]

  connection {
    type = "ssh"
    private_key = var.infra_private_key
    user = var.vm_os_user
    host = var.infra_host
  }

  provisioner "remote-exec" {
    inline = [
      "ln -s /opt/igns /var/www/html",
      "ln -s /install/bios.raw.gz /var/www/html/install/bios.raw.gz"
    ]
  }
}

resource "null_resource" "web_server_created" {
  depends_on = [
    null_resource.expose_ign_files
  ]
  provisioner "local-exec" {
    command = "echo 'Web server created'"
  }
}