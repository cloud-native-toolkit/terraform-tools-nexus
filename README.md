# Nexus operator terraform module

This module installs Nexus via an operator into a cluster and adds a ConfigMap and
Secret that contains the url and credentials for the installed instance.

## Supported platforms

This module supports the following Kubernetes distros

- Kubernetes
- OCP 3.11
- OCP 4.3

## Module dependencies

This module has the following dependencies:

- The target cluster needs to be configured
- Operator Lifecycle Manager (OLM) must be installed. On OCP 4.3, OLM is provided out
of the box. For IKS and OCP 3.X OLM must be installed.
- The target namespace must already have been created


## Example usage

```hcl-terraform
module "dev_tools_nexus" {
  source = "github.com/ibm-garage-cloud/terraform-tools-nexus.git?v1.0.0"

  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type        = module.dev_cluster.type_code
  olm_namespace       = module.dev_software_olm.olm_namespace
  operator_namespace  = module.dev_software_olm.target_namespace
  app_namespace       = module.dev_cluster_namespaces.tools_namespace_name
  ingress_subdomain   = module.dev_cluster.ingress_hostname
  name                = "nexus"
}

```
