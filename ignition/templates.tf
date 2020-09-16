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
  replicas: ${length(var.master_ips)}
metadata:
  name: ${var.cluster_name}
platform:
  vsphere:
    vcenter: ${var.vcenter_url}
    username: ${var.vsphere_user}
    password: ${var.vsphere_password}
    datacenter: ${var.datacenter}
    defaultDatastore: ${var.datastore}
pullSecret: '${chomp(base64decode(var.openshift_pull_secret))}'
sshKey: ${var.public_ssh_key}
proxy:
    httpProxy: http://${var.proxy_host}
    httpsProxy: http://${var.proxy_host}
    noProxy: ${join(",", var.no_proxies)}
EOF
}

data "template_file" "append_ignition_template" {
  template = <<EOF
{
"ignition": {
  "config": {
    "append": [
      {
        "source": "http://${var.infra_ip}:8080/ignition",
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

//data "template_file" "ifcfg-master" {
//  count = length(var.master_ips)
//
//  template = <<EOF
//TYPE=Ethernet
//NAME="ens192"
//DEVICE="ens192"
//ONBOOT=yes
//NETBOOT=yes
//BOOTPROTO=none
//IPADDR="${var.master_ips[count.index]}"
//NETMASK="${cidrnetmask("${var.gateway}/${var.network_prefix}")}"
//GATEWAY="${var.gateway}"
//DNS1="${var.dns[0]}"
//EOF
//}
//
//data "template_file" "ifcfg-worker" {
//  count = length(var.worker_ips)
//
//  template = <<EOF
//TYPE=Ethernet
//NAME="ens192"
//DEVICE="ens192"
//ONBOOT=yes
//NETBOOT=yes
//BOOTPROTO=none
//IPADDR="${var.worker_ips[count.index]}"
//NETMASK="${cidrnetmask("${var.gateway}/${var.network_prefix}")}"
//GATEWAY="${var.gateway}"
//DNS1="${var.dns[0]}"
//EOF
//}
//
//data "template_file" "ifcfg-bootstrap" {
//  template = <<EOF
//TYPE=Ethernet
//NAME="ens192"
//DEVICE="ens192"
//ONBOOT=yes
//NETBOOT=yes
//BOOTPROTO=none
//IPADDR="${var.bootstrap_ip}"
//NETMASK="${cidrnetmask("${var.gateway}/${var.network_prefix}")}"
//GATEWAY="${var.gateway}"
//DNS1="${var.dns[0]}"
//EOF
//}

resource "local_file" "install_config_yaml" {
  content  = data.template_file.install_config_yaml.rendered
  filename = "${local.installer_workspace}/install-config.yaml"
  depends_on = [
    null_resource.download_binaries,
  ]
}

resource "local_file" "append_ignition" {
  content = data.template_file.append_ignition_template.rendered
  filename = "${local.installer_workspace}/append.ign"
  depends_on = [
    null_resource.download_binaries
  ]
}