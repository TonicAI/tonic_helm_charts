#!/bin/bash

# script to update tonic
set -ex

. ./version.env

NAMESPACE="tonic"

kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}

helm3 upgrade tonic . \
    --install \
    --namespace ${NAMESPACE} \
    --dry-run \
    --values "values.yaml" \
    --set tonicVersion="$VERSION" \
    --set tonicdb.user="$TONIC_DB_USER" \
    --set tonicdb.password="$TONIC_DB_PASSWORD" \
    --set tonicLicense="$TONIC_LICENSE" \
    --set tonicSmtpConfig.smtpPassword="$TONIC_SMTP_PASSWORD"\
    --set dockerConfigAuth="$TONIC_DOCKER_AUTH" \
    --set tonicSsoConfig.clientId="$TONIC_SSO_CLIENT_ID"

