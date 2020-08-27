// Resources to create
resource "vsphere_virtual_machine" "bootstrap" {
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
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "${var.iso_folder}/${var.clustername}-bootstrap.iso"
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
  wait_for_guest_ip_timeout = 10

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
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "${var.iso_folder}/${var.clustername}-master${count.index}.iso"
  }
}

resource "vsphere_virtual_machine" "workers" {
  count = length(var.master_ips)
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
    datastore_id = data.vsphere_datastore.datastore.id
    path = "${var.iso_folder}/${var.clustername}-worker${count.index}.iso"
  }
}

//resource "vsphere_virtual_machine" "storage" {
//  for_each = var.storage.machines
//  depends_on = [vsphere_virtual_machine.masters]
//
//  name                 = each.key
//  folder               = var.storage.location
//
//  resource_pool_id     = data.vsphere_resource_pool.pool.id
//  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
//
//  num_cpus             = 16
//  memory               = 65536
//  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
//  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
//  enable_disk_uuid     = true
//  wait_for_guest_ip_timeout = 15
//
//  network_interface {
//    network_id        = data.vsphere_network.network.id
//    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
//    mac_address       = each.value["macAddress"]
//    use_static_mac    = true
//  }
//
//  disk {
//    label            = "disk0"
//    size             = var.workers.disk.size
//    unit_number      = 0
//    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
//    thin_provisioned = true
//    keep_on_remove   = false
//  }
//
//  disk {
//    label            = "disk1"
//    size             = var.storage.disk.cephSize
//    unit_number      = 1
//    eagerly_scrub    = false
//    thin_provisioned = true
//    keep_on_remove   = false
//  }
//
//  clone {
//    template_uuid    = data.vsphere_virtual_machine.master-worker-template.id
//  }
//
//  vapp {
//    properties = {
//      "guestinfo.ignition.config.data.encoding" = "base64"
//      "guestinfo.ignition.config.data" = var.ignition_files.worker
//    }
//  }
//}