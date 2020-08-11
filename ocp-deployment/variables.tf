// vSphere Variable
variable "vsphere_options" {}

// OCP Variables
variable "bootstrap_ip" {}
variable "master_ips" {}
variable "worker_ips" {}
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