#!/usr/bin/env sh

CLUSTER_TYPE="$1"
OPERATOR_NAMESPACE="$2"
OLM_NAMESPACE="$3"

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

YAML_FILE=${TMP_DIR}/nexus-subscription.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nexus-operator-hub
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: nexus-operator-hub
  source: $SOURCE
  sourceNamespace: $OLM_NAMESPACE
EOL

set -e

kubectl apply -f ${YAML_FILE} -n "${OPERATOR_NAMESPACE}"

set +e

sleep 2
until kubectl get crd/nexus.apps.m88i.io 1>/dev/null 2>/dev/null; do
  echo "Waiting for Nexus operator to install"
  sleep 30
done
