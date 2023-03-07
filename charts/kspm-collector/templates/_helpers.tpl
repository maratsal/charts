{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kspmCollector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kspmCollector.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" | lower -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kspmCollector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the kspm collector specific service account to use
*/}}
{{- define "kspmCollector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "kspmCollector.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Define the proper imageRegistry to use for agent and kmodule image
*/}}
{{- define "kspmCollector.imageRegistry" -}}
{{- if and .Values.global (hasKey (default .Values.global dict) "imageRegistry") -}}
    {{- .Values.global.imageRegistry -}}
{{- else -}}
    {{- .Values.image.registry -}}
{{- end -}}
{{- end -}}


{{/*
Return the proper image name for the KSPM Collector
*/}}
{{- define "kspmCollector.image.kspmCollector" -}}
    {{- include "kspmCollector.imageRegistry" . -}} / {{- .Values.image.repository -}} {{- if .Values.image.digest -}} @ {{- .Values.image.digest -}} {{- else -}} : {{- .Values.image.tag -}} {{- end -}}
{{- end -}}

{{/*
KSPM Collector labels
*/}}
{{- define "kspmCollector.labels" -}}
helm.sh/chart: {{ include "kspmCollector.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.labels }}
{{- $tp := typeOf .Values.labels }}
{{- if eq $tp "string" }}
{{- if not (regexMatch "^[a-z0-9A-Z].*(: )(.*[a-z0-9A-Z]$)?" .Values.labels) }}
    {{- fail "labels does not seem to be of the type key:[space]value" }}
{{- end }}
{{ tpl .Values.labels . }}
{{- else }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The following helper functions are all designed to use global values where
possible, but accept overrides from the chart values.
*/}}
{{- define "kspmCollector.accessKey" -}}
    {{- required "A valid accessKey is required" (.Values.sysdig.accessKey | default .Values.global.sysdig.accessKey) -}}
{{- end -}}

{{- define "kspmCollector.accessKeySecret" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.sysdig.accessKeySecret was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- .Values.sysdig.existingAccessKeySecret | default .Values.global.sysdig.accessKeySecret | default "" -}}
{{- end -}}

{{- define "kspmCollector.clusterName" -}}
    {{- .Values.clusterName | default .Values.global.clusterConfig.name | default "" -}}
{{- end -}}

{{/*
Determine collector endpoint based on provided region or .Values.apiEndpoint
*/}}
{{- define "kspmCollector.apiEndpoint" -}}
    {{- if .Values.apiEndpoint -}}
        {{- .Values.apiEndpoint -}}
    {{- else if (eq .Values.global.sysdig.region "us1") -}}
        {{- "secure.sysdig.com" -}}
    {{- else if (eq .Values.global.sysdig.region "us2") -}}
        {{- "us2.app.sysdig.com" -}}
    {{- else if (eq .Values.global.sysdig.region "us3") -}}
        {{- "app.us3.sysdig.com" -}}
    {{- else if (eq .Values.global.sysdig.region "us4") -}}
        {{- "app.us4.sysdig.com" -}}
    {{- else if (eq .Values.global.sysdig.region "eu1") -}}
        {{- "eu1.app.sysdig.com" -}}
    {{- else if (eq .Values.global.sysdig.region "au1") -}}
        {{- "app.au1.sysdig.com" -}}
    {{- end -}}
{{- end -}}

{{/*
Sysdig NATS service URL
*/}}
{{- define "kspmCollector.natsUrl" -}}
{{- if .Values.natsUrl -}}
    {{- .Values.natsUrl -}}
{{- else -}}
    wss://{{ (include "kspmCollector.apiEndpoint" .) }}:443
{{- end -}}
{{- end -}}


{{/*
 Helper to define if to enable nats_insecure
*/}}
{{- define "kspmCollector.natsInsecure" -}}
{{- if and (hasKey .Values "sslVerifyCertificate") ( .Values.sslVerifyCertificate ) -}}
    "false"
{{- else if and (hasKey .Values.global "sslVerifyCertificate") ( .Values.global.sslVerifyCertificate ) -}}
    "false"
{{- else -}}
    "true"
{{- end -}}
{{- end -}}


{{/*
Returns the namespace for installing components
*/}}
{{- define "kspmCollector.namespace" -}}
    {{- coalesce .Values.namespace .Release.Namespace -}}
{{- end -}}

{{/*
KSPM Collector nodeSelector
*/}}
{{- define "kspmCollector.nodeSelector" -}}
{{- if .Values.nodeSelector }}
{{- $tp := typeOf .Values.nodeSelector }}
{{- if eq $tp "string" }}
{{- if not (regexMatch "^[a-z0-9A-Z].*(: )(.*[a-z0-9A-Z]$)?" .Values.nodeSelector) }}
    {{- fail "nodeSelector does not seem to be of the type key:[space]value" }}
{{- end }}
{{ tpl .Values.nodeSelector . }}
{{- else }}
{{ toYaml .Values.nodeSelector }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Returns string 'true' if the cluster's kubeVersion is less than the parameter provided, or nothing otherwise
     Use like: {{ include "kspmCollector.kubeVersionLessThan" (dict "root" . "major" <kube_major_to_compare> "minor" <kube_minor_to_compare>) }}

     Note: The use of `"root" .` in the parameter dict is necessary as the .Capabilities fields are not provided in
           helper functions when "helm template" is used.
*/}}
{{- define "kspmCollector.kubeVersionLessThan" }}
{{- if (and (le (.root.Capabilities.KubeVersion.Major | int) .major)
            (lt (.root.Capabilities.KubeVersion.Minor | trimSuffix "+" | int) .minor)) }}
true
{{- end }}
{{- end }}

{{/*
SSL CA Filename

This is used to get the filename which is used when we create the volume inside the container
*/}}
{{- define "kspmCollector.sslCaFileName" -}}
    {{- if include "kspmCollector.existingCaSecret" . }}
      {{- include "kspmCollector.existingCaSecretFileName" . -}}
    {{- else if include "kspmCollector.existingCaConfigMap" . }}
      {{- include "kspmCollector.existingCaConfigMapFileName" . -}}
    {{- else if .Values.ssl.ca.cert }}
      {{- required "A valid fileName is required for kspmCollector.ssl.ca.fileName" (.Values.ssl.ca.fileName) -}}
    {{- else if .Values.global.ssl.ca.cert }}
      {{- required "A valid fileName is required for global.ssl.ca.fileName" (.Values.global.ssl.ca.fileName) -}}
    {{- end }}
{{- end -}}


{{/*
Append Lets Encrypt Root CA to CA provided

We use this function as a boolean helper as well as printing out the CA to determine what particular
keys are enabled or disabled.

We append the Sysdig CA as there are edge cases that might not require the
custom CA to get out to download the prebuilt agent probe but require the CA to verify the backend.
*/}}
{{- define "kspmCollector.printCA" -}}
    {{- if or (include "kspmCollector.existingCaSecret" .) (include "kspmCollector.existingCaConfigMap" .) }}
      {{- printf "%s" "true" -}}
    {{- else if .Values.ssl.ca.cert }}
      {{- printf "%s%s" .Values.ssl.ca.cert (.Files.Get "sysdig_ca.toml") -}}
    {{- else if .Values.global.ssl.ca.cert }}
      {{- printf "%s%s" .Values.global.ssl.ca.cert (.Files.Get "sysdig_ca.toml") -}}
    {{- else }}
      {{- default "" -}}
    {{- end }}
{{- end -}}

{{/*
Template to determine the existing Secret name to be used for Custom CA
*/}}
{{- define "kspmCollector.existingCaSecret" -}}
    {{- if .Values.ssl.ca.existingCaSecret }}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace .Values.ssl.ca.existingCaSecret) }}
      {{- if $secret }}
        {{- required "A valid secretName must be provided when using kspmCollector.ssl.ca.existingCaSecret" .Values.ssl.ca.existingCaSecret -}}
      {{- else }}
          {{ fail "Your kspmCollector.ssl.ca.existingCaSecret does not exist." }}
      {{- end }}
    {{- else if .Values.global.ssl.ca.existingCaSecret }}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace .Values.global.ssl.ca.existingCaSecret) }}
      {{- if $secret }}
        {{- required "A valid secretName must be provided when using global.ssl.ca.existingCaSecret" .Values.global.ssl.ca.existingCaSecret -}}
      {{- else }}
          {{ fail "Your global.ssl.ca.existingCaSecret does not exist." }}
      {{- end }}
    {{- end }}
{{- end -}}

{{/*
Template to determine the existing Secret filename defined inside the Secret
This is used when we specify the agent ca_certificate as well as the SSL_CERT_FILE environment variable
*/}}
{{- define "kspmCollector.existingCaSecretFileName" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.sysdig.existingCaSecretFileName was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- required "A filename is required for ssl.ca.existingCaSecretFileName" (.Values.ssl.ca.existingCaSecretFileName | default .Values.global.ssl.ca.existingCaSecretFileName | default "") -}}
{{- end -}}

{{/*
Template to determine the existing ConfigMap name to be used for Custom CA
*/}}
{{- define "kspmCollector.existingCaConfigMap" -}}
    {{- if .Values.ssl.ca.existingCaConfigMap }}
      {{- $secret := (lookup "v1" "ConfigMap" .Release.Namespace .Values.ssl.ca.existingCaConfigMap) }}
      {{- if $secret }}
        {{- required "A valid configMap name must be provided when using kspmCollector.ssl.ca.existingCaConfigMap" .Values.ssl.ca.existingCaConfigMap -}}
      {{- else }}
          {{ fail "Your kspmCollector.ssl.ca.existingCaConfigMap does not exist." }}
      {{- end }}
    {{- else if .Values.global.ssl.ca.existingCaConfigMap }}
      {{- $secret := (lookup "v1" "ConfigMap" .Release.Namespace .Values.global.ssl.ca.existingCaConfigMap) }}
      {{- if $secret }}
        {{- required "A valid configMap name must be provided when using global.ssl.ca.existingCaConfigMap" .Values.global.ssl.ca.existingCaConfigMap -}}
      {{- else }}
          {{ fail "Your global.ssl.ca.existingCaConfigMap does not exist." }}
      {{- end }}
    {{- end }}
{{- end -}}

{{/*
Template to determine the existing ConfigMap filename defined inside the ConfigMap
This is used when we specify the agent ca_certificate as well as the SSL_CERT_FILE environment variable
*/}}
{{- define "kspmCollector.existingCaConfigMapFileName" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.ssl.ca.existingCaConfigMapFileName was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- required "A filename is required for ssl.ca.existingCaConfigMapFileName" (.Values.ssl.ca.existingCaConfigMapFileName | default .Values.global.ssl.ca.existingCaConfigMapFileName | default "") -}}
{{- end -}}
