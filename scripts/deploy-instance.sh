
CLUSTER_TYPE="$1"
NAMESPACE="$2"
INGRESS_SUBDOMAIN="$3"
NAME="$4"
OUTPUT_FILE="$5"

if [[ -z "${NAME}" ]]; then
  NAME=nexus
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=".tmp"
fi
mkdir -p "${TMP_DIR}"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HOST="${NAME}-${NAMESPACE}.${INGRESS_SUBDOMAIN}"
fi

YAML_FILE=${TMP_DIR}/nexus-instance-${NAME}.yaml

cat <<EOL > ${YAML_FILE}
apiVersion: apps.m88i.io/v1alpha1
kind: Nexus
metadata:
  name: $NAME
spec:
  networking:
    expose: true
  persistence:
    persistent: true
    volumeSize: 10Gi
  replicas: 1
  resources:
    limits:
      cpu: '2'
      memory: 2Gi
    requests:
      cpu: '1'
      memory: 2Gi
  useRedHatImage: false
EOL

kubectl apply -f ${YAML_FILE} -n "${NAMESPACE}"

sleep 2

kubectl rollout status deployment/${NAME} -n "${NAMESPACE}" || exit 1

if [[ -n "${OUTPUT_FILE}" ]]; then
  POD_NAME=$(kubectl get pods -n "${NAMESPACE}" -l app=${NAME} -o jsonpath='{range .items[]}{.metadata.name}{"\n"}{end}')
  kubectl exec "pod/${POD_NAME}" -n "${NAMESPACE}" cat /nexus-data/admin.password > "${OUTPUT_FILE}"
fi
