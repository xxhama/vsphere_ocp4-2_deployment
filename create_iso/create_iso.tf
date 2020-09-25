resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

locals {
  all_hostnames = concat(list(var.bootstrap), var.masters, var.workers)
  all_ips       = concat(list(var.bootstrap_ip), var.master_ips, var.worker_ips)
  all_count     = 7
  esc_pass      = replace(var.vsphere_password,"!", "\\!")
  all_type = concat(
  data.template_file.bootstrap_type.*.rendered,
  data.template_file.master_type.*.rendered,
  data.template_file.worker_type.*.rendered,
  )
  all_index = concat(
  data.template_file.bootstrap_index.*.rendered,
  data.template_file.master_index.*.rendered,
  data.template_file.worker_index.*.rendered,
  )
}

data "template_file" "bootstrap_type" {
  count    = 1
  template = "bootstrap"
}

data "template_file" "master_type" {
  count    = 3
  template = "master"
}

data "template_file" "worker_type" {
  count    = 3
  template = "worker"
}

data "template_file" "bootstrap_index" {
  count    = 1
  template = count.index
}

data "template_file" "master_index" {
  count    = 3
  template = count.index
}

data "template_file" "worker_index" {
  count    = 3
  template = count.index
}

resource "null_resource" "downloadiso" {
  depends_on = [
    null_resource.dependency
  ]

  connection {
    host = var.infranode_ip
    user = var.username
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "yum install -y wget",
      "yum install -y mkisofs",
      "curl -sL -o /tmp/installer.iso ${var.binaries["openshift_iso"]}",
      "test -e /tmp/tempiso || mkdir /tmp/tempiso",
      "sudo mount /tmp/installer.iso /tmp/tempiso",
      "test -e /tmp/iso || mkdir /tmp/iso",
      "cp -r /tmp/tempiso/* /tmp/iso/",
      "sudo umount /tmp/tempiso",
      "sudo chmod -R u+w /tmp/iso/",
      "sed -i 's/default vesamenu.c32/default linux/g' /tmp/iso/isolinux/isolinux.cfg",
      "curl -sL -o /tmp/govc.gz ${var.binaries["govc"]}",
      "gunzip /tmp/govc.gz",
      "sudo chmod 755 /tmp/govc",
      "sudo mv /tmp/govc /usr/local/bin/",
      "chmod +x /usr/local/bin/govc",
      "mkdir /install/",
      "curl -sL -o /install/bios.raw.gz ${var.binaries["openshift_bios"]} "
    ]
  }
}

locals {
    coreos_netmask = var.netmask
    nameservers    = join(" ", formatlist("nameserver=%v", var.openshift_nameservers))
  }

resource "null_resource" "generateisos" {
  triggers = {
    master_hostnames  = join(",", var.masters)
    master_ips        = join(",", var.master_ips)
    worker_hostnames  = join(",", var.workers)
    worker_ips        = join(",", var.worker_ips)

  }
  count = local.all_count
  depends_on = [
    null_resource.downloadiso
  ]

  connection {
    host        = var.infranode_ip
    user        = var.username
    private_key = var.ssh_private_key
  }


  provisioner "remote-exec" {
    inline = [
      "cp -Rp /tmp/iso /tmp/${local.all_hostnames[count.index]}",
      "sed -i 's/coreos.inst=yes/coreos.inst=yes ip=${local.all_ips[count.index]}::${var.gateway}:${local.coreos_netmask}:${local.all_hostnames[count.index]}.${var.ocp_cluster}.${var.base_domain}:ens192:none ${local.nameservers} coreos.inst.install_dev=sda coreos.inst.image_url=http:\\/\\/${var.infranode_ip}:8080\\/install\\/bios.raw.gz coreos.inst.ignition_url=http:\\/\\/${var.infranode_ip}:8080\\/igns\\/${local.all_hostnames[count.index]}.ign/g' /tmp/${local.all_hostnames[count.index]}/isolinux/isolinux.cfg",
      "mkisofs -o /tmp/${var.ocp_cluster}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso -rational-rock -J -joliet-long -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table /tmp/${local.all_hostnames[count.index]} > /dev/null 2>&1",
      "export GOVC_URL=${var.vsphere_url}",
      "export GOVC_USERNAME=${var.vsphere_username}",
      "export GOVC_PASSWORD=${local.esc_pass}",
      "export GOVC_INSECURE=${var.vsphere_allow_insecure}",
      "govc datastore.upload -ds=${var.vsphere_image_datastore} -dc=${var.vsphere_data_center} /tmp/${var.ocp_cluster}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso ${var.vsphere_image_datastore_path}/${var.ocp_cluster}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso  > /dev/null 2>&1"
    ]
  }


  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export GOVC_URL=${var.vsphere_url}",
      "export GOVC_USERNAME=${var.vsphere_username}",
      "export GOVC_PASSWORD=${local.esc_pass}",
      "export GOVC_INSECURE=${var.vsphere_allow_insecure}",
      "govc datastore.rm -ds=${var.vsphere_image_datastore} -dc=${var.vsphere_data_center} ${var.vsphere_image_datastore_path}/${var.ocp_cluster}-${local.all_type[count.index]}-${local.all_index[count.index]}.iso  > /dev/null 2>&1"
    ]
  }
}

resource "null_resource" "images_created" {
  depends_on = [
    null_resource.generateisos
  ]
  provisioner "local-exec" {
    command = "echo 'Iso images created'"
  }
}