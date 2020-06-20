provider "helm" {
  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${local.host}"
  password_file = "${path.cwd}/nexus-password.val"
  password      = data.local_file.nexus-password.content
}

resource "null_resource" "nexus-subscription" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-subscription.sh ${var.cluster_type} ${var.operator_namespace} ${var.olm_namespace} ${var.app_namespace}"

    environment = {
      TMP_DIR    = local.tmp_dir
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "nexus-instance" {
  depends_on = [null_resource.nexus-subscription]

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-instance.sh ${var.cluster_type} ${var.app_namespace} ${var.ingress_subdomain} ${var.name} ${local.password_file}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

data "local_file" "nexus-password" {
  depends_on = [null_resource.nexus-instance]

  filename = local.password_file
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type == "ocp4" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=nexus || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "nexus-config" {
  depends_on = [null_resource.nexus-instance, null_resource.delete-consolelink]

  name         = "nexus"
  repository   = "https://ibm-garage-cloud.github.io/toolkit-charts/"
  chart        = "tool-config"
  namespace    = var.app_namespace
  force_update = true

  set {
    name  = "url"
    value = local.host
  }

  set {
    name  = "username"
    value = "admin"
  }

  set {
    name  = "password"
    value = local.password
  }

  set {
    name  = "applicationMenu"
    value = var.cluster_type != "kubernetes"
  }

  set {
    name  = "ingressSubdomain"
    value = var.ingress_subdomain
  }

  set {
    name  = "name"
    value = "Nexus"
  }
}
