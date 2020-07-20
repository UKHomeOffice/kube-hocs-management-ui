#!/bin/bash

export KUBE_NAMESPACE=${ENVIRONMENT}
export KUBE_SERVER=${KUBE_SERVER}

if [[ -z ${VERSION} ]] ; then
    export VERSION=${IMAGE_VERSION}
fi
if [[ -z ${DOMAIN} ]] ; then
    export DOMAIN="cs"
fi
export DOMAIN=${DOMAIN}

if [[ ${KUBE_NAMESPACE} == "cs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_MANAGEMENT_UI_CS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_CS_PROD}
    export REPLICAS="2"
elif [[ ${KUBE_NAMESPACE} == "wcs-prod" ]] ; then
    echo "deploy ${VERSION} to PROD namespace, using HOCS_MANAGEMENT_UI_WCS_PROD drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_WCS_PROD}
    export REPLICAS="2"
elif [[ ${KUBE_NAMESPACE} == "cs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_MANAGEMENT_UI_CS_QA drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_CS_QA}
    export REPLICAS="2"
elif [[ ${KUBE_NAMESPACE} == "wcs-qa" ]] ; then
    echo "deploy ${VERSION} to QA namespace, using HOCS_MANAGEMENT_UI_WCS_QA drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_WCS_QA}
    export REPLICAS="2"
elif [[ ${KUBE_NAMESPACE} == "cs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, HOCS_MANAGEMENT_UI_CS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_CS_DEMO}
    export REPLICAS="1"
elif [[ ${KUBE_NAMESPACE} == "wcs-demo" ]] ; then
    echo "deploy ${VERSION} to DEMO namespace, HOCS_MANAGEMENT_UI_WCS_DEMO drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_WCS_DEMO}
    export REPLICAS="1"
elif [[ ${KUBE_NAMESPACE} == "cs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, HOCS_MANAGEMENT_UI_CS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_CS_DEV}
    export REPLICAS="1"
elif [[ ${KUBE_NAMESPACE} == "wcs-dev" ]] ; then
    echo "deploy ${VERSION} to DEV namespace, HOCS_MANAGEMENT_UI_WCS_DEV drone secret"
    export KUBE_TOKEN=${HOCS_MANAGEMENT_UI_WCS_DEV}
    export REPLICAS="1"
else
    echo "Unable to find environment: ${ENVIRONMENT}"
fi

if [[ -z ${KUBE_TOKEN} ]] ; then
    echo "Failed to find a value for KUBE_TOKEN - exiting"
    exit -1
fi

if [[ "${KUBE_NAMESPACE}" == "wcs-prod" ]] ; then
    export DNS_PREFIX=www.wcs-management
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/HOCS
elif [[ "${KUBE_NAMESPACE}" == "cs-prod" ]] ; then
    export DNS_PREFIX=www.cs-management
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/hocs-prod
elif [[ "${KUBE_NAMESPACE}" == "cs-dev" ]] ; then
    export DNS_PREFIX=dev-management.internal.cs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
elif [[ "${KUBE_NAMESPACE}" == "wcs-dev" ]] ; then
    export DNS_PREFIX=dev-management.wcs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
elif [[ "${KUBE_NAMESPACE}" == "cs-qa" ]] ; then
    export DNS_PREFIX=qa-management.internal.cs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
elif [[ "${KUBE_NAMESPACE}" == "wcs-qa" ]] ; then
    export DNS_PREFIX=qa-management.wcs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
elif [[ "${KUBE_NAMESPACE}" == "cs-demo" ]] ; then
    export DNS_PREFIX=demo-management.cs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
elif [[ "${KUBE_NAMESPACE}" == "wcs-demo" ]] ; then
    export DNS_PREFIX=demo-management.wcs-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
else
    export DNS_PREFIX=${DOMAIN}-management.${DOMAIN}-notprod
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
fi

export DOMAIN_NAME=${DNS_PREFIX}.homeoffice.gov.uk

if [[ $DNS_PREFIX == *"internal"* ]]; then
  export INGRESS_TYPE="internal"
else
  export INGRESS_TYPE="external"
fi

echo
echo "Deploying hocs-management-ui to ${ENVIRONMENT}"
echo "Keycloak realm: ${KC_REALM}"
echo "Keycloak domain: ${KC_DOMAIN}"
echo "${INGRESS_TYPE} name: ${DOMAIN_NAME}"
echo

cd kd

kd --insecure-skip-tls-verify \
   --timeout 10m \
    -f ingress-${INGRESS_TYPE}.yaml \
    -f deployment.yaml \
    -f service.yaml \
    -f autoscale.yaml
