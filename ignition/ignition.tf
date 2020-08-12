locals {
  installer_workspace     = "${path.root}/installer-files"
  openshift_installer_url = "${var.openshift_installer_url}/${var.openshift_version}"
  cluster_nr              = element(split("-", var.cluster_name), 1)
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
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${local.installer_workspace} -A 'openshift-install-linux-4*.tar.gz'
    tar zxvf ${local.installer_workspace}/openshift-install-linux-4*.tar.gz -C ${local.installer_workspace}
    wget -r -l1 -np -nd -q ${local.openshift_installer_url} -P ${local.installer_workspace} -A 'openshift-client-linux-4*.tar.gz'
    tar zxvf ${local.installer_workspace}/openshift-client-linux-4*.tar.gz -C ${local.installer_workspace}
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
    command = "${local.installer_workspace}/openshift-install --dir=${local.installer_workspace} create manifests"
  }
}

resource "null_resource" "generate_ignition" {
  depends_on = [
    null_resource.generate_manifests
  ]

  provisioner "local-exec" {
    command = <<EOF
${local.installer_workspace}/openshift-install --dir=${local.installer_workspace} create ignition-configs
EOF
  }
}

resource "null_resource" "create_append_ignition" {

}

data "local_file" "master_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/master.ign"
}

data "local_file" "append_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/append.ign"
}

data "local_file" "worker_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/worker.ign"
}

data "local_file" "bootstrap_ign" {
  depends_on = [null_resource.generate_ignition]
  filename = "${local.installer_workspace}/bootstrap.ign"
}