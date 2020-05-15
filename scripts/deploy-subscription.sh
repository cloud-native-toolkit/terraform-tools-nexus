#!/usr/bin/env sh

CLUSTER_TYPE="$1"
OPERATOR_NAMESPACE="$2"
OLM_NAMESPACE="$3"
APP_NAMESPACE="$4"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  SOURCE="community-operators"
else
  SOURCE="operatorhubio-catalog"
fi

if [[ -z "${OLM_NAMESPACE}" ]]; then
  if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
    OLM_NAMESPACE="openshift-marketplace"
  else
    OLM_NAMESPACE="olm"
  fi
fi

if [[ "${OPERATOR_NAMESPACE}" == "${APP_NAMESPACE}" ]]; then
  # we are installing the operator into a namespace instead of cluster-wide
  # create a operatorgroup
  OPERATOR_GROUP_YAML=${TMP_DIR}/nexus-operatorgroup.yaml

  cat <<EOL > ${OPERATOR_GROUP_YAML}
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nexus-operatorgroup
spec:
  targetNamespaces:
  - ${OPERATOR_NAMESPACE}
EOL

  kubectl apply -f ${OPERATOR_GROUP_YAML} -n "${OPERATOR_NAMESPACE}"
fi

SUBSCRIPTION_YAML=${TMP_DIR}/nexus-subscription.yaml

cat <<EOL > ${SUBSCRIPTION_YAML}
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nexus-operator-m88i
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: nexus-operator-m88i
  source: $SOURCE
  sourceNamespace: $OLM_NAMESPACE
EOL

set -e

kubectl apply -f ${SUBSCRIPTION_YAML} -n "${OPERATOR_NAMESPACE}"

set +e

sleep 2
until kubectl get crd/nexus.apps.m88i.io 1>/dev/null 2>/dev/null; do
  echo "Waiting for Nexus operator to install"
  sleep 30
done
