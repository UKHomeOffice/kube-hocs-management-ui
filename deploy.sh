#!/bin/bash
set -euo pipefail

export KUBE_NAMESPACE=${ENVIRONMENT:-$DRONE_DEPLOY_TO}
export KUBE_TOKEN=${KUBE_TOKEN}
export VERSION=${VERSION}

export DOMAIN="cs"
if [ "${KUBE_NAMESPACE%-*}" == "wcs" ]; then
    export DOMAIN="wcs"
fi

export SUBNAMESPACE="${KUBE_NAMESPACE#*-}" # e.g. dev, qa

if [[ ${SUBNAMESPACE} == "prod" ]]
then
    export MIN_REPLICAS="2"
    export MAX_REPLICAS="6"
    export KUBE_SERVER=https://kube-api-prod.prod.acp.homeoffice.gov.uk
    export UPTIME_PERIOD="Mon-Sun 05:00-23:00 Europe/London"
    export KUBE_CERTIFICATE_AUTHORITY="https://raw.githubusercontent.com/UKHomeOffice/acp-ca/master/acp-prod.crt"
else
    export MIN_REPLICAS="1"
    export MAX_REPLICAS="2"
    export KUBE_SERVER=https://kube-api-notprod.notprod.acp.homeoffice.gov.uk
    export KC_REALM=https://sso-dev.notprod.homeoffice.gov.uk/auth/realms/hocs-notprod
    export UPTIME_PERIOD="Mon-Fri 08:00-18:00 Europe/London"
    export KUBE_CERTIFICATE_AUTHORITY="https://raw.githubusercontent.com/UKHomeOffice/acp-ca/master/acp-notprod.crt"
fi

if [[ "${KUBE_NAMESPACE}" == "wcs-prod" ]] ; then
    export DNS_PREFIX=www.wcs-management
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/HOCS
elif [[ "${KUBE_NAMESPACE}" == "cs-prod" ]] ; then
    export DNS_PREFIX=www.cs-management
    export KC_REALM=https://sso.digital.homeoffice.gov.uk/auth/realms/hocs-prod
else
    export DNS_PREFIX="$SUBNAMESPACE-management.internal.$DOMAIN-notprod"
fi

export DOMAIN_NAME=${DNS_PREFIX}.homeoffice.gov.uk

export INGRESS_TYPE="external"
if [[ $DNS_PREFIX == *"internal"* ]]; then
  export INGRESS_TYPE="internal"
fi

echo
echo "Deploying hocs-management-ui to ${ENVIRONMENT}"
echo "Keycloak realm: ${KC_REALM}"
echo "${INGRESS_TYPE} name: ${DOMAIN_NAME}"
echo

cd kd || exit 1

kd --timeout 10m \
    -f ingress-${INGRESS_TYPE}.yaml \
    -f deployment.yaml \
    -f service.yaml \
    -f autoscale.yaml
