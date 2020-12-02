provider "helm" {
  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir       = "${path.cwd}/.tmp"
  host          = "${var.name}-${var.app_namespace}.${var.ingress_subdomain}"
  url_endpoint  = "https://${local.host}"
  name                   = "nexus"
  gitops_dir             = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name             = "nexus"
  chart_dir              = "${local.gitops_dir}/${local.chart_name}"
  global_config          = {
    clusterType = var.cluster_type
    ingressSubdomain = var.ingress_subdomain
  }
  service_account_config = {
    name = var.service_account
    sccs = ["anyuid", "privileged"]
  }
  nexus_operator_config  = {
    olmNamespace = var.olm_namespace
    operatorNamespace = var.operator_namespace
    serviceAccount = var.service_account
    app = local.name
  }
}

resource "null_resource" "setup-chart" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=${local.name} || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "local_file" "nexus-values" {
  depends_on = [null_resource.setup-chart, null_resource.delete-consolelink]

  content  = yamlencode({
    global = local.global_config
    service-account = local.service_account_config
    nexus-operator = local.nexus_operator_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.nexus-values.filename}"
  }
}

resource "null_resource" "scc-cleanup" {
  depends_on = [local_file.nexus-values]
  count = var.mode != "setup" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete scc -l app.kubernetes.io/name=${local.name} --wait 1> /dev/null 2> /dev/null || true"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "nexus" {
  depends_on = [local_file.nexus-values, null_resource.scc-cleanup]
  count = var.mode != "setup" ? 1 : 0

  name              = "nexus"
  chart             = local.chart_dir
  namespace         = var.app_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
