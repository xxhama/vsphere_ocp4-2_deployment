// Resources to create
resource "vsphere_virtual_machine" "bootstrap" {
  name                 = "bootstrap"

  folder               = var.bootstrap.location
  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id

  num_cpus             = 8
  memory               = 16384
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
    mac_address       = var.bootstrap.macAddress
    use_static_mac    = true
  }

  disk {
    label            = "disk0"
    size             = 120
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  clone {
    template_uuid    = data.vsphere_virtual_machine.master-worker-template.id
  }

  vapp {
    properties = {
      "guestinfo.ignition.config.data.encoding" = "base64"
      "guestinfo.ignition.config.data" = var.ignition_files.append_bootstrap
    }
  }
}

resource "vsphere_virtual_machine" "masters" {
  for_each = var.masters.ips
  depends_on = [vsphere_virtual_machine.bootstrap]

  name                 = "master-${each.key}"
  folder               = var.masters.location

  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id

  num_cpus             = 16
  memory               = 65536
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true
  wait_for_guest_ip_timeout = 10

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
    ipv4_address      = each.value
  }

  disk {
    label            = "disk0"
    size             = var.masters.disk.size
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  clone {
    template_uuid    = data.vsphere_virtual_machine.master-worker-template.id
  }

  vapp {
    properties = {
      "guestinfo.ignition.config.data.encoding" = "base64"
      "guestinfo.ignition.config.data" = var.ignition_files.master
    }
  }
}

resource "vsphere_virtual_machine" "workers" {
  for_each = var.workers.machines
  depends_on = [vsphere_virtual_machine.masters]

  name                 = each.key
  folder               = var.workers.location

  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id

  num_cpus             = 8
  memory               = 16384
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true
  wait_for_guest_ip_timeout = 15

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
    mac_address       = each.value["macAddress"]
    use_static_mac    = true
  }

  disk {
    label            = "disk0"
    size             = var.workers.disk.size
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  clone {
    template_uuid    = data.vsphere_virtual_machine.master-worker-template.id
  }

  vapp {
    properties = {
      "guestinfo.ignition.config.data.encoding" = "base64"
      "guestinfo.ignition.config.data" = var.ignition_files.worker
    }
  }
}

resource "vsphere_virtual_machine" "storage" {
  for_each = var.storage.machines
  depends_on = [vsphere_virtual_machine.masters]

  name                 = each.key
  folder               = var.storage.location

  resource_pool_id     = data.vsphere_resource_pool.pool.id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id

  num_cpus             = 16
  memory               = 65536
  guest_id             = data.vsphere_virtual_machine.master-worker-template.guest_id
  scsi_type            = data.vsphere_virtual_machine.master-worker-template.scsi_type
  enable_disk_uuid     = true
  wait_for_guest_ip_timeout = 15

  network_interface {
    network_id        = data.vsphere_network.network.id
    adapter_type      = data.vsphere_virtual_machine.master-worker-template.network_interface_types[0]
    mac_address       = each.value["macAddress"]
    use_static_mac    = true
  }

  disk {
    label            = "disk0"
    size             = var.workers.disk.size
    unit_number      = 0
    eagerly_scrub    = data.vsphere_virtual_machine.master-worker-template.disks[0].eagerly_scrub
    thin_provisioned = true
    keep_on_remove   = false
  }

  disk {
    label            = "disk1"
    size             = var.storage.disk.cephSize
    unit_number      = 1
    eagerly_scrub    = false
    thin_provisioned = true
    keep_on_remove   = false
  }

  clone {
    template_uuid    = data.vsphere_virtual_machine.master-worker-template.id
  }

  vapp {
    properties = {
      "guestinfo.ignition.config.data.encoding" = "base64"
      "guestinfo.ignition.config.data" = var.ignition_files.worker
    }
  }
}