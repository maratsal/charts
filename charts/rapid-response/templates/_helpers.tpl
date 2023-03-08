{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "rapidResponse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | lower }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rapidResponse.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" | lower }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride | lower }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" | lower }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | lower }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rapidResponse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | lower }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rapidResponse.labels" -}}
helm.sh/chart: {{ include "rapidResponse.chart" . }}
{{ include "rapidResponse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rapidResponse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rapidResponse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Daemonset labels
*/}}
{{- define "rapidResponse.daemonSetLabels" -}}
  {{- if .Values.rapidResponse.daemonSetLabels }}
    {{- $tp := typeOf .Values.rapidResponse.daemonSetLabels }}
    {{- if eq $tp "string" }}
        {{- if not (regexMatch "^[a-z0-9A-Z].*(: )(.*[a-z0-9A-Z]$)?" .Values.rapidResponse.daemonSetLabels) }}
            {{- fail "daemonSetLabels does not seem to be of the type key:[space]value" }}
        {{- end }}
        {{- tpl .Values.rapidResponse.daemonSetLabels . }}
    {{- else }}
        {{- toYaml .Values.rapidResponse.daemonSetLabels }}
    {{- end }}
  {{- end }}
{{- end -}}

{{/*
Define the proper imageRegistry to use for Rapid Response image
*/}}
{{- define "rapidResponse.imageRegistry" -}}
{{- if and .Values.global (hasKey (default .Values.global dict) "imageRegistry") -}}
    {{- required "A valid global registry name is required" .Values.global.imageRegistry -}}
{{- else -}}
    {{- required "A valid registry name is required" .Values.rapidResponse.image.registry  -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Rapid Response image name
*/}}
{{- define "rapidResponse.repositoryName" -}}
    {{- required "A valid repository name is required" .Values.rapidResponse.image.repository -}}
{{- end -}}

{{- define "rapidResponse.image" -}}
{{- if .Values.rapidResponse.overrideValue }}
    {{- printf .Values.rapidResponse.overrideValue -}}
{{- else -}}
    {{- include "rapidResponse.imageRegistry" . -}} / {{- include "rapidResponse.repositoryName" . -}} {{- if .Values.rapidResponse.image.digest -}} @ {{- .Values.rapidResponse.image.digest -}} {{- else -}} : {{- include "rapidResponse.imageTag" . -}} {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return Rapid Response image tag from AppVersion defined on Chart.yaml
This would avoid to manually update everytime both Chart.yaml and values.yaml with the new image tag
*/}}
{{- define "rapidResponse.imageTag" -}}
{{- if .Values.rapidResponse.image.tag -}}
    {{- $tp := typeOf .Values.rapidResponse.image.tag }}
    {{- if ne $tp "string" }}
      {{- fail "Rapid Response image tag does not seems to be a string" }}
    {{- else }}
        {{- printf "%s" .Values.rapidResponse.image.tag -}}
    {{- end }}
{{- else -}}
{{- printf "%s" .Chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{/*
The following helper functions are all designed to use global values where
possible, but accept overrides from the chart values.
*/}}

{{- define "rapidResponse.accessKey" -}}
    {{- required "A valid accessKey is required" (.Values.sysdig.accessKey | default .Values.global.sysdig.accessKey) -}}
{{- end -}}

{{- define "rapidResponse.accessKeySecret" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.sysdig.accessKeySecret was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- .Values.sysdig.existingAccessKeySecret | default .Values.global.sysdig.accessKeySecret | default "" -}}
{{- end -}}

{{- define "rapidResponse.passphrase" -}}
    {{- required "A valid passphrase is required" .Values.rapidResponse.passphrase  -}}
{{- end -}}

{{- define "rapidResponse.passphraseSecret" -}}
    {{- .Values.rapidResponse.existingPassphraseSecret | default "" -}}
{{- end -}}

{{/*
HTTP/HTTPS proxy support
*/}}
{{- define "rapidResponse.httpProxy" -}}
    {{- if (.Values.rapidResponse.proxy.httpProxy | default .Values.global.proxy.httpProxy) -}}
        {{ .Values.rapidResponse.proxy.httpProxy | default .Values.global.proxy.httpProxy }}
    {{- end -}}
{{- end -}}

{{- define "rapidResponse.httpsProxy" -}}
    {{- if (.Values.rapidResponse.proxy.httpsProxy | default .Values.global.proxy.httpsProxy) -}}
        {{ .Values.rapidResponse.proxy.httpsProxy | default .Values.global.proxy.httpsProxy }}
    {{- end -}}
{{- end -}}

{{- define "rapidResponse.noProxy" -}}
    {{- if (.Values.rapidResponse.proxy.noProxy | default .Values.global.proxy.noProxy) -}}
        {{ .Values.rapidResponse.proxy.noProxy | default .Values.global.proxy.noProxy }}
    {{- end -}}
{{- end -}}

{{/*
Determine collector endpoint based on provided region or .Values.rapidResponse.apiEndpoint
*/}}
{{- define "rapidResponse.apiEndpoint" -}}
    {{- if .Values.rapidResponse.apiEndpoint -}}
        {{- .Values.rapidResponse.apiEndpoint -}}
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
    {{- else -}}
        {{- fail (printf "global.sysdig.region=%s provided is not recognized." .Values.global.sysdig.region ) -}}
    {{- end -}}
{{- end -}}

{{/*
Rapid Response have the environment variable skip_tls_check: true for skip the certficate verification
while we do the other way round for our other components (sslVerifyCertificate: false for disabling the check).
The aim of rapidResponse.certificateValidation is to align the settings with the other Sysdig charts,
without introducing changes on Rapid Response container image.
*/}}
{{- define "rapidResponse.certificateValidation" -}}
    {{- if or ( eq (.Values.rapidResponse.skipTlsVerifyCertificate | toString) "true") (eq (.Values.rapidResponse.sslVerifyCertificate | toString) "false") -}}
        {{- "true" -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{/*
Create the name of the Rapid Response collector specific service account to use
*/}}
{{- define "rapidResponse.serviceAccountName" -}}
{{- if .Values.rapidResponse.serviceAccount.create -}}
    {{ default (include "rapidResponse.fullname" .) .Values.rapidResponse.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.rapidResponse.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* Returns string 'true' if the cluster's kubeVersion is less than the parameter provided, or nothing otherwise
     Use like: {{ include "rapidResponse.kubeVersionLessThan" (dict "root" . "major" <kube_major_to_compare> "minor" <kube_minor_to_compare>) }}

     Note: The use of `"root" .` in the parameter dict is necessary as the .Capabilities fields are not provided in
           helper functions when "helm template" is used.
*/}}
{{- define "rapidResponse.kubeVersionLessThan" }}
{{- if (and (le (.root.Capabilities.KubeVersion.Major | int) .major)
            (lt (.root.Capabilities.KubeVersion.Minor | trimSuffix "+" | int) .minor)) }}
true
{{- end }}
{{- end }}

{{/*
SSL CA Filename

This is used to get the filename which is used when we create the volume inside the container
*/}}
{{- define "rapidResponse.sslCaFileName" -}}
    {{- if include "rapidResponse.existingCaSecret" . }}
      {{- include "rapidResponse.existingCaSecretFileName" . -}}
    {{- else if include "rapidResponse.existingCaConfigMap" . }}
      {{- include "rapidResponse.existingCaConfigMapFileName" . -}}
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
{{- define "rapidResponse.printCA" -}}
    {{- if or (include "rapidResponse.existingCaSecret" .) (include "rapidResponse.existingCaConfigMap" .) }}
      {{- printf "%s" "true" -}}
    {{- else if .Values.global.ssl.ca.cert }}
      {{- printf "%s%s" .Values.global.ssl.ca.cert (.Files.Get "sysdig_ca.toml") -}}
    {{- else }}
      {{- default "" -}}
    {{- end }}
{{- end -}}

{{/*
Template to determine the existing Secret name to be used for Custom CA
*/}}
{{- define "rapidResponse.existingCaSecret" -}}
    {{- if .Values.rapidResponse.ssl.ca.existingCaSecret }}
      {{- $secret := (lookup "v1" "Secret" .Release.Namespace .Values.rapidResponse.ssl.ca.existingCaSecret) }}
      {{- if $secret }}
        {{- required "A valid secretName must be provided when using rapidResponse.ssl.ca.existingCaSecret" .Values.rapidResponse.ssl.ca.existingCaSecret -}}
      {{- else }}
          {{ fail "Your rapidResponse.ssl.ca.existingCaSecret does not exist." }}
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
{{- define "rapidResponse.existingCaSecretFileName" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.sysdig.existingCaSecretFileName was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- required "A filename is required for rapidResponse.ssl.ca.existingCaSecretFileName" (.Values.rapidResponse.ssl.ca.existingCaSecretFileName | default .Values.global.ssl.ca.existingCaSecretFileName | default "") -}}
{{- end -}}

{{/*
Template to determine the existing ConfigMap name to be used for Custom CA
*/}}
{{- define "rapidResponse.existingCaConfigMap" -}}
    {{- if .Values.rapidResponse.ssl.ca.existingCaConfigMap }}
      {{- $secret := (lookup "v1" "ConfigMap" .Release.Namespace .Values.rapidResponse.ssl.ca.existingCaConfigMap) }}
      {{- if $secret }}
        {{- required "A valid configMap name must be provided when using rapidResponse.ssl.ca.existingCaConfigMap" .Values.rapidResponse.ssl.ca.existingCaConfigMap -}}
      {{- else }}
          {{ fail "Your rapidResponse.ssl.ca.existingCaConfigMap does not exist." }}
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
{{- define "rapidResponse.existingCaConfigMapFileName" -}}
    {{/*
    Note: the last default function call is to avoid some weirdness when either
    argument is nil. If .Values.global.ssl.ca.existingCaConfigMapFileName was undefined, the
    returned empty string does not evaluate to empty on Helm Version:"v3.8.0"
    */}}
    {{- required "A filename is required for rapidResponse.ssl.ca.existingCaConfigMapFileName" (.Values.rapidResponse.ssl.ca.existingCaConfigMapFileName | default .Values.global.ssl.ca.existingCaConfigMapFileName | default "") -}}
{{- end -}}
