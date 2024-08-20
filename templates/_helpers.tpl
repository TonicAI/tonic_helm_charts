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

{{- define "tonic.deployStrategy" -}}
{{- if .Values.deployStrategy -}}
{{- .Values.deployStrategy -}}
{{- else -}}
{{ "RollingUpdate" }}
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
{{- else if eq $provider "oidc" }}
{{- include "tonic.sso.oidc" . }}
{{- else }}
{{ fail "Unsupported SSO provider " .provider }}
{{ end }}
{{- end -}}
{{/* end tonic.sso */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure AWS sso
*/}}
{{- define "tonic.sso.aws" -}}
{{- if (.metadataXml).url -}}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_URL
  value: {{ quote .metadataXml.url }}
{{- else if (.metadataXml).base64 }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_BASE64
  value: {{ quote .metadataXml.base64 }}
{{- else if .samlIdpMetadataXml }}
- name: TONIC_SSO_SAML_IDP_METADATA_XML_BASE64
  value: {{ quote .samlIdpMetadataXml }}
{{- else -}}
{{ fail "Either metadataXml.url, metadataXml.base64 or samlIdpMetadataXml must be provided to configure AWS sso" }}
{{- end -}}
{{- end -}}
{{/* end tonic.sso.aws */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure Azure sso
*/}}
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
{{/* end tonic.sso.azure */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure Duo sso
*/}}
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
{{/* end tonic.sso.duo */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure Google sso
*/}}
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
{{/* end tonic.sso.google */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure Okta sso
*/}}
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
{{/* end tonic.sso.okta */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure Keycloak sso
*/}}
{{- define "tonic.sso.keycloak" -}}
- name: TONIC_SSO_REALM_ID
  value: {{ required "tonicSsoConfig.realmId is required to configure Keycloak sso" .realmId | quote }}
- name: TONIC_SSO_DOMAIN
  value: {{ required "tonicSsoConfig.domain is required to configure Keycloak sso" .domain | quote }}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure Keycloak sso" .clientId | quote }}
{{- end -}}
{{/* end tonic.sso.keycloak */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure generic saml sso
*/}}
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
{{/* end tonic.sso.saml */}}

{{/*
Given $.Values.tonicSsoConfig, produces the environment variables needed to
configure generic oidc sso
*/}}
{{- define "tonic.sso.oidc" -}}
- name: TONIC_SSO_CLIENT_ID
  value: {{ required "tonicSsoConfig.clientId is required to configure OIDC sso" .clientId | quote }}
- name: TONIC_SSO_OIDC_AUTHORITY
  value: {{ required "tonicSsoConfig.authority is required to configure OIDC sso" .authority | quote }}
{{- if .optionalConfig.scopes }}
- name: TONIC_SSO_OIDC_SCOPES
  value: {{ quote .optionalConfig.scopes }}
{{- end }}
{{- if .optionalConfig.firstNameClaimName }}
- name: TONIC_SSO_OIDC_FIRST_NAME_CLAIM_NAME
  value: {{ quote .optionalConfig.firstNameClaimName }}
{{- end }}
{{- if .optionalConfig.lastNameClaimName }}
- name: TONIC_SSO_OIDC_LAST_NAME_CLAIM_NAME
  value: {{ quote .optionalConfig.lastNameClaimName }}
{{- end }}
{{- if .optionalConfig.emailClaimName }}
- name: TONIC_SSO_OIDC_EMAIL_CLAIM_NAME
  value: {{ quote .optionalConfig.emailClaimName }}
{{- end }}
{{- if .optionalConfig.groupsClaimName }}
- name: TONIC_SSO_OIDC_GROUPS_CLAIM_NAME
  value: {{ quote .optionalConfig.groupsClaimName }}
{{- end }}
{{- end -}}
{{/* end tonic.sso.oidc */}}

{{/*
About `$top := first .` and `(list $)`

`$` always points at the root value for this context. However, inside of a
named template, our context is different than inside of a template directly.
Many of these named templates accept a list where the first argument is `$` --
or `$top` inside the template -- which allows it access the root context of the
caller (which is ideally the root value of the chart).
*/}}

{{- define "tonic.nodeSelectors" -}}
{{- $top := first . }}
{{- $selectors := dict }}
{{- if ($top.Values).nodeSelector }}
{{- $selectors = merge $selectors $top.Values.nodeSelector }}
{{- if (gt (len .) 1) }}
{{- $selectors = merge $selectors (index . 1) }}
{{- end }}
{{- if $selectors }}
{{- $selectors | toYaml }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tonic.tolerations" -}}
{{- $top := first . }}
{{- $tolerations := list }}
{{- if ($top.Values).tolerations }}
{{- $tolerations = concat $tolerations $top.Values.tolerations }}
{{- end }}
{{- if (gt (len .) 1) }}
{{- $these := (index . 1) }}
{{- if $these }}
{{- $tolerations = concat $tolerations $these }}
{{- end }}
{{- end }}
{{- if $tolerations }}
{{- toYaml $tolerations }}
{{- end }}
{{- end }}

{{- define "tonic.annotations" -}}
{{- $top := first . }}
{{- $annotations := dict }}
{{- if ($top.Values).annotations }}
{{- $annotations = (merge $annotations $top.Values.annotations) }}
{{- end }}
{{- if (gt (len .) 1) }}
{{- $these := (index . 1) }}
{{- if $these }}
{{- $annotations = (merge $annotations $these) }}
{{- end }}
{{- end }}
{{- if $annotations }}
{{- $annotations | toYaml }}
{{- end }}
{{- end -}}

{{- define "tonic.allLabels" -}}
{{- $top := first . }}
{{- $labels := dict }}
{{- if ($top.Values).labels }}
{{- $labels = (merge $labels $top.Values.labels) }}
{{- end }}
{{- if (gt (len .) 1) }}
{{- $these := (index . 1) }}
{{- if $these }}
{{- $labels = (merge $labels $these) }}
{{- end }}
{{- end }}
{{- if $labels -}}
{{- $labels | toYaml }}
{{- end }}
{{ include "tonic.labels" $top }}
{{- end -}}

{{- define "tonic.initContainers" -}}
{{- $top := first . }}
{{- $inits := index . 1 }}
{{- if $inits }}
{{- toYaml $inits }}
{{- end }}
{{- end }}

{{- define "tonic.unprivilegeImage" -}}
{{- $top := first . }}
{{- $image := index . 1  }}
{{- if $top.Values.useUnprivilegedContainers }}
{{- $image }}_unprivileged
{{- else }}
{{- $image }}
{{- end }}
{{- end }}

{{- define "tonic.image" -}}
{{- $top := first . }}
{{- $custImage := index . 1 }}
{{- $ourImage := index . 2 }}
{{- if $custImage }}
{{- $custImage }}
{{- else }}
{{- include "tonic.unprivilegeImage" (list $top $ourImage) }}
{{- end }}
{{- end }}

{{- define "tonic.imageWithVersion" -}}
{{- $top := first . }}
{{- $custImage := index . 1 }}
{{- $ourImage := index . 2 }}
{{- $version := (index . 3) |  default "latest" }}
{{- include "tonic.image" (list $top $custImage $ourImage) }}:{{ $version }}
{{- end }}

{{/* usage:
    $ports := fromYaml (include "tonic.ports" (list $ $service.ports (dict "http" 1337 "https" 31337 "httpsOnly" true)))
*/}}
{{- define "tonic.ports" -}}
{{- $top := first . }}
{{- $passed := dict }}
{{- if and (gt (len .) 1) (index . 1) }}
{{ $passed = index . 1 }}
{{- end }}
{{- $defaults := dict }}
{{- if and (gt (len .) 2) (index . 2) }}
{{- $defaults = index . 2 }}
{{- end }}
{{- $useUnprivileged := false }}
{{- if hasKey $top.Values "useUnprivilegedContainers" }}
{{ $useUnprivileged = $top.Values.useUnprivilegedContainers }}
{{- end }}
{{- $unprivilegedHttp := 8080 }}
{{- if and $defaults.http (lt 1024 $defaults.http) }}
{{- $unprivilegedHttp = $defaults.http }}
{{- end }}
{{- $unprivilegedHttps := 8443 }}
{{- if and $defaults.https (lt 1024 $defaults.https) }}
{{- $unprivilegedHttps = $defaults.https }}
{{- end }}
{{- $http := int (coalesce $passed.http $defaults.http $unprivilegedHttp) }}
{{- $https := int (coalesce $passed.https $defaults.https $unprivilegedHttps) }}
{{/* `$passed.httpsOnly | default true` flips an explicit false off */}}
{{/* `coalesce $passed.httpsOnly $defaults.httpsOnly true` will bypass false values and return true */}}
{{- $httpsOnly := true }}
{{- if hasKey $passed "httpsOnly" }}
{{- $httpsOnly = $passed.httpsOnly }}
{{- else if hasKey $defaults "httpsOnly" }}
{{- $httpsOnly = $defaults.httpsOnly }}
{{- end }}
{{/* 1024 is usually where privileged ports end */}}
{{- if and $useUnprivileged (ge 1024 $http) -}}
{{- $http = $unprivilegedHttp }}
{{- end }}
{{- if and $useUnprivileged (ge 1024 $https) -}}
{{- $https = $unprivilegedHttps }}
{{- end }}
{{/* break most places the http port would be placed if it's erronously accessed */}}
{{- $thesePorts := (dict "http" "HTTP PORT NOT AVAILABLE" "https" $https "httpsOnly" $httpsOnly) }}
{{- if not $thesePorts.httpsOnly }}
{{- $_ := set $thesePorts "http" $http }}
{{- end }}
{{ toYaml $thesePorts }}
{{- end }}

{{- define "tonic.web.serviceType" -}}
{{- $top := first . }}
{{- $useIngress := $top.Values.tonicai.use_ingress }}
{{- if $useIngress }}
{{- printf "ClusterIP" }}
{{- else }}
{{- printf "LoadBalancer" }}
{{- end }}
{{- end }}
