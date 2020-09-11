locals {
  installer_workspace     = "${path.module}/installer-files"
  openshift_installer_url = "${var.openshift_installer_url}/${var.openshift_version}"
}

//# Proxy TLS Cert
//resource "null_resource" "download_proxy_cert" {
//  provisioner "local-exec" {
//    when = create
//    command = "echo | openssl s_client -showcerts -connect ${var.proxy_host}:${var.proxy_port} 2>/dev/null | openssl x509 -outform PEM > ca.crt"
//  }
//
//  provisioner "local-exec" {
//    when = destroy
//    command = "rm -rf ${local.installer_workspace}/ca.crt"
//  }
//}
//data "local_file" "proxy_cert" {
//  depends_on = [null_resource.download_proxy_cert]
//  filename = "${local.installer_workspace}/ca.crt"
//}

resource "null_resource" "download_binaries" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
test -e ${local.installer_workspace} || mkdir ${local.installer_workspace}
case $(uname -s) in
  Darwin)
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${local.installer_workspace} -A 'openshift-install-mac-4*.tar.gz'
    tar zxvf ${local.installer_workspace}/openshift-install-mac-4*.tar.gz -C ${local.installer_workspace}
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${local.installer_workspace} -A 'openshift-client-mac-4*.tar.gz'
    tar zxvf ${local.installer_workspace}/openshift-client-mac-4*.tar.gz -C ${local.installer_workspace}
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64 -O ${local.installer_workspace}/jq > /dev/null 2>&1\
    ;;
  Linux)
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${local.installer_workspace} -A 'openshift-install-linux-4*.tar.gz,openshift-client-linux-4*.tar.gz'
    tar zxvf ${local.installer_workspace}/openshift-client-linux-4*.tar.gz -C ${local.installer_workspace}
    tar zxvf ${local.installer_workspace}/openshift-install-linux-4*.tar.gz -C ${local.installer_workspace}
    wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ${local.installer_workspace}/jq
    ;;
  *)
    exit 1;;
esac
chmod u+x ${local.installer_workspace}/jq
rm -f ${local.installer_workspace}/*.tar.gz ${local.installer_workspace}/robots*.txt* ${local.installer_workspace}/README.md
EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${local.installer_workspace}"
  }

}

resource "null_resource" "generate_manifests" {
  triggers = {
    install_config = data.template_file.install_config_yaml.rendered
  }

  depends_on = [
    null_resource.download_binaries,
    local_file.install_config_yaml,
  ]

  provisioner "local-exec" {
    command = <<EOF
cp ${local.installer_workspace}/install-config.yaml install-config.yaml.backup
${local.installer_workspace}/openshift-install --dir=${local.installer_workspace} create manifests
EOF
  }
}

resource "null_resource" "generate_ignition" {
  depends_on = [
    null_resource.generate_manifests
  ]

  provisioner "local-exec" {
    command = <<EOF
${local.installer_workspace}/openshift-install --dir=${local.installer_workspace} create ignition-configs
cat ${local.installer_workspace}/auth/kubeconfig | base64 -w0
EOF
  }
}


resource "null_resource" "inject_network_config_workers" {
  depends_on = [null_resource.generate_ignition]
  count = length(var.worker_ips)
  provisioner "local-exec" {
    command = <<EOF
jq -c '.storage += {"files": [{"path": "/etc/hostname","mode": 420,"contents": {"source": "data:,worker${count.index}.${var.cluster_name}"},"filesystem": "root"}]}' ${local.installer_workspace}/worker.ign > ${local.installer_workspace}/worker${count.index}.ign_modified
EOF
  }
}

resource "null_resource" "inject_network_config_masters" {
  depends_on = [null_resource.generate_ignition]
  count = length(var.master_ips)
  provisioner "local-exec" {
    command = <<EOF
jq -c '.storage += {"files": [{"path": "/etc/hostname","mode": 420,"contents": {"source": "data:,master${count.index}.${var.cluster_name}"},"filesystem": "root"}]}' ${local.installer_workspace}/master.ign > ${local.installer_workspace}/master${count.index}.ign_modified
EOF
  }
}

data "local_file" "kubeadmin_password" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/auth/kubeadmin-password"
}

data "local_file" "master_igns" {
  depends_on = [null_resource.inject_network_config_masters]
  count = length(var.master_ips)
  filename = "${local.installer_workspace}/master${count.index}.ign_modified"
}

data "local_file" "append_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/append.ign"
}

data "local_file" "worker_igns" {
  depends_on = [null_resource.inject_network_config_workers]
  count = length(var.worker_ips)
  filename = "${local.installer_workspace}/worker${count.index}.ign_modified"
}

data "local_file" "bootstrap_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/bootstrap.ign"
}

data "local_file" "kubeconfig" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/auth/kubeconfig"
}