# Nexus operator terraform module

This module installs Nexus via an operator into a cluster and adds a ConfigMap and
Secret that contains the url and credentials for the installed instance.

## Module dependencies

This module has the following dependencies:

- The target cluster needs to be configured
- Operator Lifecycle Manager (OLM) must be installed. On OCP 4.3, OLM is provided out
of the box. For IKS and OCP 3.X OLM must be installed.
- The target namespace must already have been created

These dependencies can be met by using the 

## Supported platforms

 