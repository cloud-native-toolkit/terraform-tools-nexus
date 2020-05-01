
resource "null_resource" "nexus-subscription" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/subscription.yaml -n ${var.operator_namespace}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "nexus-role" {
  depends_on = [null_resource.nexus-subscription]

  provisioner "local-exec" {
    command = "cat ${path.module}/operator-role.yaml | sed \"s/SA_NAMESPACE/${var.operator_namespace}/g\" | kubectl apply -f - -n ${var.app_namespace}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "nexus-repo-install" {
  depends_on = [null_resource.nexus-role]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/nexus-repo.yaml -n ${var.app_namespace}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "nexus-repo-patch" {
  depends_on = [null_resource.nexus-repo-install]

  provisioner "local-exec" {
    command = "kubectl patch deployment/nexusrepo-sonatype-nexus --type json -p='[{\"op\": \"add\", \"path\": \"/spec/template/spec/serviceAccount\", \"value\": \"nexus\"}]' -n ${var.app_namespace}"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}