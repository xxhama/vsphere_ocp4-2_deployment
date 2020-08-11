// vSphere Variable
variable "vsphere_datacenter" {}
variable "vsphere_datastore" {}
variable "vsphere_resource_pool" {}
variable "vsphere_network" {}
variable "folder" {}

// OCP Variables
variable "bootstrap_ip" {}
variable "master_ips" {}
variable "worker_ips" {}
variable "rhcos_template_path" {}

// Ignition Files
variable "master_ign" {}
variable "worker_ign" {}
variable "append_ign" {}

// Data objects
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "master-worker-template" {
  name          = var.rhcos_template_path
  datacenter_id = data.vsphere_datacenter.dc.id
}

// Example Data
vsphere_options = {
  resource_pool_name = "resource_pool_name",
  datastore_cluster_name = "datastore_cluster_name",
  vsphere_user = "vsphere_username_here",
  vsphere_password = "vsphere_password_here",
  vsphere_server = "vcsa.csplab.local",
  vsphere_datacenter = "CSPLAB"
}

bootstrap = {
  location = "Sandbox/your_project_name",
  macAddress = "00:50:56:a5:5b:ad"
}

masters = {
  location = "Sandbox/your_project_name",
  disk = {
    size = 120
  },
  machines = {
    control-plane-00 = {
      macAddress = "00:50:56:a5:d0:ec"
    },
    control-plane-01 = {
      macAddress = "00:50:56:a5:45:2d"
    },
    control-plane-02 = {
      macAddress = "00:50:56:a5:5e:08"
    }
  }
}

workers = {
  location = "Sandbox/your_project_name",
  disk = {
    size = 120
  },
  machines = {
    compute-00 = {
      macAddress: "00:50:56:a5:4d:5f"
    },
    compute-01 = {
      macAddress: "00:50:56:a5:9a:02"
    },
    compute-02 = {
      macAddress: "00:50:56:a5:bd:44"
    }
  }
}

storage = {
  location = "Sandbox/your_project_name"
  disk = {
    size = 200
    cephSize = 500
  },
  machines = {
    storage-00 = {
      macAddress: "00:50:56:a5:f5:68"
    },
    storage-01 = {
      macAddress: "00:50:56:a5:d8:3d"
    },
    storage-02 = {
      macAddress: "00:50:56:a5:d7:06"
    }
  }
}

load-balancers = {
  compute: {
    macAddress = "00:50:56:a5:8d:5e"
  }
  control: {
    macAddress = "00:50:56:a5:d2:96"
  }
}

ignition_files = {
  master = "base64_ign",
  worker = "base64_ign",
  append_bootstrap = "base64_ign"
}