#!/bin/bash

# script to update tonic
set -ex

. ./version.env

# use staging env variables
if [ ${deployTargetKey} == "eq-staging" ];then
    NAMESPACE="tonic-staging"
    TONIC_DB_USER="postgres"
    TONIC_DB_PASSWORD=$TONIC_DB_PASSWORD_STAGING
else
    NAMESPACE="tonic"
fi

kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}

helm3 upgrade tonic . \
    --install \
    --namespace ${NAMESPACE} \
    --values "values.yaml" \
    --values "values-${deployTargetKey}.yml" \
    --set tonicVersion="$VERSION" \
    --set tonicdb.user="$TONIC_DB_USER" \
    --set tonicdb.password="$TONIC_DB_PASSWORD" \
    --set tonicLicense="$TONIC_LICENSE" \
    --set tonicSmtpConfig.smtpPassword="$TONIC_SMTP_PASSWORD"\
    --set dockerConfigAuth="$TONIC_DOCKER_AUTH" \
    --set tonicSsoConfig.clientId="$TONIC_SSO_CLIENT_ID"

