
resource "null_resource" "create_lb_server_dependsOn" {
  provisioner "local-exec" {
    # Hack to force dependencies to work correctly. Must use the dependsOn var somewhere in the code for dependencies to work. Contain value which comes from previous module.
    command = "echo The dependsOn output for lb server module is ${var.dependsOn}"
  }
}


resource "null_resource" "create_lb_server" {
  depends_on = [null_resource.create_lb_server_dependsOn]
  # count      = var.install == "true" ? 1 : 0
  connection {
    type                = "ssh"
    user                = var.vm_os_user
    private_key         = var.vm_os_private_key
    host                = var.vm_ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/setup_lb.sh"
    destination = "/tmp/setup_lb.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy.cfg"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/setup_lb.sh",
      "bash -c '/tmp/setup_lb.sh' ",
    ]
  }
}
 
resource "null_resource" "lb_server_create" {
  depends_on = [
    null_resource.create_lb_server,
    #null_resource.create_lb_server_dependsOn
  ]
  provisioner "local-exec" {
    command = "echo 'HAPRoxy LB server created'"
  }
}