module "dev_serviceaccount_nexus" {
  source = "github.com/ibm-garage-cloud/terraform-cluster-serviceaccount.git?ref=v1.3.0"

  cluster_type             = module.dev_cluster.type_code
  cluster_config_file_path = module.dev_cluster.config_file_path
  namespace                = module.dev_capture_tools_state.namespace
  service_account_name     = "nexus"
  sscs                     = ["anyuid", "privileged"]
}


module "dev_tools_nexus" {
  source = "./module"

  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type        = module.dev_cluster.type_code
  ingress_subdomain   = module.dev_cluster.ingress_hostname
  olm_namespace       = module.dev_capture_olm_state.namespace
  operator_namespace  = module.dev_capture_operator_state.namespace
  app_namespace       = module.dev_serviceaccount_nexus.namespace
  service_account     = module.dev_serviceaccount_nexus.name
  name                = "nexus"
}
