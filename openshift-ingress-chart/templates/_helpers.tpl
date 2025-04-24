{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-ingress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
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
{{- printf "%s-%s-tls" $.global.tls.secretNamePrefix ($host | replace "." "-") | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-tls" $fullName ($host | replace "." "-") | trunc 63 | trimSuffix "-" }}
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
{{- $pathConfig.service.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $defaultName }}
{{- end }}
{{- else if $hostConfig.service }}
{{- if $hostConfig.service.name }}
{{- $hostConfig.service.name | trunc 63 | trimSuffix "-" }}
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
