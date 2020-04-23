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

ignition_files = {
  master = "base64_ign",
  worker = "base64_ign",
  append_bootstrap = "base64_ign"
}