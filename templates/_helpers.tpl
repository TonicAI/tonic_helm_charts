{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "tonic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tonic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tonic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tonic.labels" -}}
helm.sh/chart: {{ include "tonic.chart" . }}
{{ include "tonic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tonic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tonic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tonic.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "tonic.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- else -}}
    {{ "" }}
{{- end -}}
{{- end }}

{{- define "tonic.hostIntegration" -}}
{{- if ((.Values.tonicai).web_server).features -}}
{{- .Values.tonicai.web_server.features.host_integration_enabled -}}
{{- else -}}
{{ "false" }}
{{- end -}}
{{- end }}

{{/*
Given the $.Values.tonicSsoConfig, create all environment variables needed for
the deployment. This should only be called if $.Values.tonicSsoConfig is populated
*/}}
{{- define "tonic.sso" -}}
{{- $provider := (required "tonicSsoConfig.provider is required for SSO" .provider | lower) -}}
- name: TONIC_SSO_PROVIDER
  value: {{ quote .provider }}
{{- if .groupFilter }}
- name: TONIC_SSO_GROUP_FILTER_REGEX
  value: {{quote .groupFilter}}
{{- end }}
{{- if eq $provider "aws" }}
{{- include "tonic.sso.aws" . }}
{{- else if eq $provider "azure" }}
{{ include "tonic.sso.azure" . }}
{{- else if eq $provider "duo" }}
{{ include "tonic.sso.duo" . }}
{{- else if eq $provider "google" }}
{{ include "tonic.sso.google" . }}
{{- else if eq $provider "okta" }}
{{ include "tonic.sso.okta" . }}
{{- else if eq $provider "keycloak" }}
{{ include "tonic.sso.keycloak" . }}
{{- else if eq $provider "saml" }}
{{- include "tonic.sso.saml" . }}
{{- else }}
{{ fail "Unsupported SSO provider " .provider }}
{{ end }}
{{- end -}}

{{- define "tonic.sso.aws" -}}
{{- if (.metdataXml).url -}}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_URL
  value: {{ quote .metadataXml.url }}
{{- else if (.metdataXml).base64 }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_BASE64
  value: {{ quote .metadataXml.base64 }}
{{- else if .samlIdpMetadataXml }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_BASE64
  value: {{ quote .samlIdpMetadataXml }}
{{- else -}}
{{ fail "Either metadataXml.url, metadataXml.base64 or samlIdpMetadataXml must be provided to configure AWS sso" }}
{{- end -}}
{{- end -}}

{{- define "tonic.sso.azure" -}}
- name: TONIC_SSO_TENANT_ID
  value: {{ required "tonicSsoConfig.tenantId is required to configure Azure sso" .tenantId | quote }}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Azure sso" .clientId | quote }}
{{- if not .clientSecret }}
{{ fail "tonicSsoConfig.clientSecret is required to configure Azure sso" }}
{{- end }}
- name: TONIC_SSO_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: tonic-sso-client-secret
      key: secret
      optional: false
{{- end -}}

{{- define "tonic.sso.duo" -}}
- name: TONIC_SSO_DOMAIN
  value: {{ required "tonicSsoConfig.domain is required to configure Duo sso" .domain | quote }}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Duo sso" .clientId | quote }}
{{- if not .clientSecret }}
{{ fail "tonicSsoConfig.clientSecret is required to configure Duo sso" }}
{{- end }}
- name: TONIC_SSO_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: tonic-sso-client-secret
      key: secret
      optional: false
{{- end -}}

{{- define "tonic.sso.google" -}}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Google sso" .clientId | quote }}
{{- if not .clientSecret }}
{{ fail "tonicSsoConfig.clientSecret is required to configure Google sso" }}
{{- end }}
- name: TONIC_SSO_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: tonic-sso-client-secret
      key: secret
      optional: false
- name: TONIC_SSO_DOMAIN
  value: {{ required "tonicSsoConfig.domain is required to configure Google sso" .domain | quote }}
{{- if not .googleAccountServiceJson }}
{{ fail "tonicSsoConfig.googleAccountServiceJson is required to configure Google sso"}}
{{- end }}
- name: TONIC_SSO_SERVICE_ACCOUNT_JSON_BASE64
  valueFrom:
    secretKeyRef:
      name: tonic-sso-google-account-service-json-secret
      key: secret
      optional: false
{{- end -}}

{{- define "tonic.sso.okta" -}}
- name: TONIC_SSO_DOMAIN
  value: {{ required "tonicSsoConfig.domain is required to configure Okta sso" .domain | quote }}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Okta sso" .clientId | quote }}
{{- if .identityProviderId }}
- name: TONIC_SSO_IDENTITY_PROVIDER_ID
  value: {{ quote .identityProviderId }}
{{- end }}
{{- if .authServerId }}
- name: TONIC_SSO_AUTHORIZATION_SERVER_ID
  value: {{ quote .authServerId }}
{{- end }}
{{- end -}}

{{- define "tonic.sso.keycloak" -}}
- name: TONIC_SSO_REALM_ID
  value: {{ required "tonicSsoConfig.realmId is required to configure Keycloak sso" .realmId | quote }}
- name: TONIC_SSO_DOMAIN
  value: {{ required "tonicSsoConfig.domain is required to configure Keycloak sso" .domain | quote }}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Keycloak sso" .clientId | quote }}
{{- end -}}

{{- define "tonic.sso.saml" -}}
{{- if .entityId }}
- name: TONIC_SSO_SAML_ENTITY_ID
  value: {{ quote .entityId }}
{{- end }}
{{- if .metadataXml.url }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_URL
  value: {{ quote .metadataXml.url }}
{{- else if .metadataXml.base64 }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_BASE64
  value: {{ quote .metadataXml.base64 }}
{{- else }}
{{- fail "Either metadataXml.url or metadataXml.base64 is required" }}
{{- end -}}
{{- end -}}
