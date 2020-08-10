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
  replicas: 3
metadata:
  name: ${var.cluster_name}
platform:
  vsphere:
    vcenter: ${var.vcenter_url}
    username: ${var.vsphere_user}
    password: ${var.vsphere_password}
    datacenter: ${var.datacenter}
    defaultDatastore: ${var.datastore}
pullSecret: ${var.openshift_pull_secret}
sshKey: ${var.public_ssh_key}
proxy:
    httpProxy: ${var.proxy_host}${var.proxy_port}
    httpsProxy: ${var.proxy_host}${var.proxy_port}
additionalTrustBundle: |
${data.local_file.proxy_cert.content}
EOF
}

resource "local_file" "install_config_yaml" {
  content  = data.template_file.install_config_yaml.rendered
  filename = "${local.installer_workspace}/install-config.yaml"
  depends_on = [
    null_resource.download_binaries,
  ]
}