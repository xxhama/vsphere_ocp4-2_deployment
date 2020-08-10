data "template_file" "install_config_yaml" {
  template = <<EOF
apiVersion: v1
baseDomain: ${var.base_domain}
compute:
- hyperthreading: Enabled
  name: worker
  platform:
    azure:
      type: ${var.worker_vm_type}
      osDisk:
        diskSizeGB: ${var.worker_os_disk_size}
        diskType: Premium_LRS
  replicas: ${base64decode(var.node_count)}
controlPlane:
  hyperthreading: Enabled
  name: master
  platform:
    azure:
      type: ${var.master_vm_type}
      osDisk:
        diskSizeGB: ${var.master_os_disk_size}
        diskType: Premium_LRS
      zones:
      - "1"
      - "2"
      - "3"
  replicas: ${var.master_count}
metadata:
  creationTimestamp: null
  name: ${var.cluster_name}
networking:
  clusterNetwork:
  - cidr: ${var.cluster_network_cidr}
    hostPrefix: ${var.cluster_network_host_prefix}
  machineNetwork:
  - cidr: ${var.machine_cidr}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.service_network_cidr}
platform:
  azure:
    region: ${var.azure_region}
    baseDomainResourceGroupName: ${var.azure_dns_resource_group_name}
    networkResourceGroupName: ${var.network_resource_group_name}
    virtualNetwork: ${var.virtual_network_name}
    controlPlaneSubnet: ${var.control_plane_subnet}
    computeSubnet: ${var.compute_subnet}
    osDisk:
      diskSizeGB: ${var.worker_os_disk_size}
      diskType: Premium_LRS
publish: ${var.private ? "Internal" : "External"}
pullSecret: '${var.openshift_pull_secret}'
sshKey: '${var.public_ssh_key}'
%{if var.airgapped["enabled"]}imageContentSources:
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${var.airgapped["repository"]}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
%{endif}
EOF
}

resource "local_file" "install_config_yaml" {
  content  = data.template_file.install_config_yaml.rendered
  filename = "${local.installer_workspace}/install-config.yaml"
  depends_on = [
    null_resource.download_binaries,
  ]
}