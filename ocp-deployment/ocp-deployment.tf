// vSphere Variable
variable "vsphere_options" {}

// OCP Variables
variable "bootstrap" {}
variable "load-balancers" {}
variable "masters" {}
variable "workers" {}
variable "storage" {}
variable "ignition_files" {}

provider "vsphere" {
  vsphere_server = var.vsphere_options.vsphere_server
  user = var.vsphere_options.vsphere_user
  password = var.vsphere_options.vsphere_password
  allow_unverified_ssl = true
  version = "< 1.16"
}

// Data objects
data "vsphere_datacenter" "dc" {
  name = var.vsphere_options.vsphere_datacenter
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.vsphere_options.datastore_cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_options.resource_pool_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "OCP"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "master-worker-template" {
  name          = "Templates/CSPLAB-Supported/rhcos-4.2.0-x86_64-vmware-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}


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
  for_each = var.masters.machines
  depends_on = [vsphere_virtual_machine.bootstrap]

  name                 = each.key
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
    mac_address       = each.value["macAddress"]
    use_static_mac    = true
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