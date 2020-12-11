
resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependsOn)
  }
}

// Resources to create
resource "vsphere_virtual_machine" "bootstrap" {

  depends_on = [
    null_resource.dependency
  ]
  name                 = "bootstrap"

  folder               = var.folder
  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_id         = data.vsphere_datastore.datastore.id

  num_cpus             = 4
  memory               = 16384
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 200
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = "${var.iso_folder}/${var.clustername}-bootstrap-0.iso"
  }
}

resource "vsphere_virtual_machine" "masters" {
  count = length(var.master_ips)
  depends_on = [vsphere_virtual_machine.bootstrap]

  name                 = "master-${count.index}"
  folder               = var.folder

  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_id         = data.vsphere_datastore.datastore.id

  num_cpus             = 16
  memory               = 65536
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true
  wait_for_guest_ip_timeout = 15

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 250
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path         = "${var.iso_folder}/${var.clustername}-master-${count.index}.iso"
  }
}

resource "vsphere_virtual_machine" "workers" {
  count = length(var.worker_ips)
  depends_on = [vsphere_virtual_machine.masters]

  name                 = "worker-${count.index}"
  folder               = var.folder

  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_id         = data.vsphere_datastore.datastore.id

  num_cpus             = 8
  memory               = 16384
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true
  wait_for_guest_ip_timeout = 30

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = 250
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  cdrom {
    datastore_id = data.vsphere_datastore.iso_datastore.id
    path = "${var.iso_folder}/${var.clustername}-worker-${count.index}.iso"
  }
}

resource "null_resource" "module_complete" {
  depends_on = [
    vsphere_virtual_machine.workers
  ]
  provisioner "local-exec" {
    command = "echo 'Module Complete'"
  }
}

