vsphere_options = {
  resource_pool_name = "pool_name",
  datastore_cluster_name = "SANDBOX_TIER4",
  vsphere_user = "your_vsphere_username",
  vsphere_password = "your_vsphere_password",
  vsphere_server = "vsphere.server.example",
  vsphere_datacenter = "data_center_name"
}

bootstrap = {
  location = "Sandbox/xhama",
  macAddress = "00:50:56:a5:5b:11"
}

masters = {
  location = "Sandbox/xhama",
  disk = {
    size = 120
  },
  machines = {
    control-plane-00 = {
      macAddress = "00:50:56:a5:d0:11"
    },
    control-plane-01 = {
      macAddress = "00:50:56:a5:45:11"
    },
    control-plane-02 = {
      macAddress = "00:50:56:a5:5e:11"
    }
  }
}

workers = {
  location = "Sandbox/xhama",
  disk = {
    size = 120
  },
  machines = {
    compute-00 = {
      macAddress: "00:50:56:a5:4d:11"
    },
    compute-01 = {
      macAddress: "00:50:56:a5:9a:11"
    },
    compute-02 = {
      macAddress: "00:50:56:a5:bd:11"
    }
  }
}

ignition_files = {
  master = "base64_encoded_master",
  worker = "base64_encoded_worker",
  append_bootstrap = "base64_encoded_appened"
}