data "template_file" "install_config_yaml" {
  template = <<EOF
apiVersion: v1
baseDomain: ${var.base_domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${var.master_count}
metadata:
  name: ${var.cluster_name}
platform:
  vsphere:
    vcenter: ${var.vcenter_url}
    username: ${var.vsphere_user}
    password: ${var.vsphere_password}
    datacenter: ${var.datacenter}
    defaultDatastore: ${var.datastore}
pullSecret: '${var.openshift_pull_secret}'
sshKey: ${var.public_ssh_key}
proxy:
    httpProxy: http://${var.proxy_host}
    httpsProxy: https://${var.proxy_host}
EOF
}

data "template_file" "append_ignition_template" {
  template = <<EOF
{
"ignition": {
  "config": {
    "append": [
      {
        "source": "http://${var.infra_ip}/ignition",
        "verification": {}
      }
    ]
  },
  "timeouts": {},
  "version": "2.1.0"
},
"networkd": {},
"passwd": {},
"storage": {},
"systemd": {}
}
EOF
}

resource "local_file" "install_config_yaml" {
  content  = data.template_file.install_config_yaml.rendered
  filename = "${local.installer_workspace}/install-config.yaml"
  depends_on = [
    null_resource.download_binaries,
  ]
}

resource "local_file" "append_ignition" {
  content = data.template_file.install_config_yaml.rendered
  filename = "${local.installer_workspace}/append.ign"
  depends_on = [
    null_resource.download_binaries
  ]
}