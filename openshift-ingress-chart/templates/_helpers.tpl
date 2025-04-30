{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-ingress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openshift-ingress.fullname" -}}
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
{{- define "openshift-ingress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Truncate a string and append a hash of the full string to maintain uniqueness.
The resulting string will be at most 63 characters long (Kubernetes name limit).
*/}}
{{- define "openshift-ingress.truncateWithHash" -}}
{{- $nameLen := len . -}}
{{- if gt $nameLen 63 }}
  {{- /* Get a hash of the entire string to maintain uniqueness */ -}}
  {{- $hash := substr 0 8 (sha256sum .) -}}
  {{- /* Reserve 9 chars for the hash plus a hyphen, leaving 54 chars for the content */ -}}
  {{- printf "%s-%s" (substr 0 54 .) $hash | trimSuffix "-" }}
{{- else }}
  {{- . }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openshift-ingress.labels" -}}
helm.sh/chart: {{ include "openshift-ingress.chart" . }}
{{ include "openshift-ingress.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openshift-ingress.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openshift-ingress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get the TLS secret name for a host
*/}}
{{- define "openshift-ingress.tlsSecretName" -}}
{{- $host := .host }}
{{- $tls := .tls }}
{{- $fullName := .fullName }}
{{- if $tls.secretName }}
{{- $tls.secretName }}
{{- else if $.global.tls.secretNamePrefix }}
{{- $secretName := printf "%s-%s-tls" $.global.tls.secretNamePrefix ($host | replace "." "-") }}
{{- include "openshift-ingress.truncateWithHash" $secretName }}
{{- else }}
{{- $secretName := printf "%s-%s-tls" $fullName ($host | replace "." "-") }}
{{- include "openshift-ingress.truncateWithHash" $secretName }}
{{- end }}
{{- end }}

{{/*
Get service name for a path configuration
*/}}
{{- define "openshift-ingress.serviceName" -}}
{{- $pathConfig := .pathConfig }}
{{- $hostConfig := .hostConfig }}
{{- $defaultName := .defaultName }}
{{- if $pathConfig.service }}
{{- if $pathConfig.service.name }}
{{- include "openshift-ingress.truncateWithHash" $pathConfig.service.name }}
{{- else }}
{{- $defaultName }}
{{- end }}
{{- else if $hostConfig.service }}
{{- if $hostConfig.service.name }}
{{- include "openshift-ingress.truncateWithHash" $hostConfig.service.name }}
{{- else }}
{{- $defaultName }}
{{- end }}
{{- else }}
{{- $defaultName }}
{{- end }}
{{- end }}

{{/*
Get service port for a path configuration
*/}}
{{- define "openshift-ingress.servicePort" -}}
{{- $pathConfig := .pathConfig }}
{{- $hostConfig := .hostConfig }}
{{- $defaultPort := .defaultPort }}
{{- if $pathConfig.service }}
{{- if $pathConfig.service.port }}
{{- $pathConfig.service.port }}
{{- else }}
{{- $defaultPort }}
{{- end }}
{{- else if $hostConfig.service }}
{{- if $hostConfig.service.port }}
{{- $hostConfig.service.port }}
{{- else }}
{{- $defaultPort }}
{{- end }}
{{- else }}
{{- $defaultPort }}
{{- end }}
{{- end }}
