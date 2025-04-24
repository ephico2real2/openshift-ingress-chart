# OpenShift Ingress Helm Chart

This document contains a complete sample Helm chart structure for configuring Ingress resources in OpenShift. The chart is designed to support both vanity URLs and wildcard routes with their respective certificates.

## Chart Structure

```
openshift-ingress-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   └── serviceaccount.yaml
└── README.md
```

## Chart.yaml

```yaml
apiVersion: v2
name: openshift-ingress
description: A Helm chart for configuring Ingress resources in OpenShift
type: application
version: 0.1.0
appVersion: "1.0.0"
```

## values.yaml

```yaml
# Default configuration for the chart
nameOverride: ""
fullnameOverride: ""

# Service account configuration
serviceAccount:
  create: true
  annotations: {}
  name: ""

# Backend service configuration
service:
  type: ClusterIP
  port: 3000

# Ingress configuration
ingress:
  enabled: true
  className: "openshift-default"  # Use OpenShift's default ingress controller
  
  # Common annotations for all ingress resources
  annotations: {}
    # kubernetes.io/ingress.class: openshift-default
    # kubernetes.io/tls-acme: "true"
  
  # OpenShift specific router annotations
  openshiftRouterAnnotations:
    haproxy.router.openshift.io/timeout: 30s
    router.openshift.io/cookie-same-site: "Lax"
    # Add other OpenShift router annotations as needed
    # route.openshift.io/termination: edge
    # haproxy.router.openshift.io/balance: roundrobin
    # haproxy.router.openshift.io/disable_cookies: 'true'
    # router.openshift.io/rewrite-target: /
  
  # Common labels for all ingress resources
  labels:
    environment: dev
    app.kubernetes.io/component: ingress
  
  # Multiple host configurations
  hosts:
    # Example of a vanity URL
    - host: dojo-portal-rnd.ephico2real.com
      annotations:
        haproxy.router.openshift.io/rate-limit-connections: 'true'
        haproxy.router.openshift.io/rate-limit-connections.rate-http: '100'
      tls:
        enabled: true
        secretName: vanity-dojo-portal-tls-secret
      paths:
        - path: /
          pathType: Prefix
          # If omitted, these will use defaults from service
          # serviceName: custom-service-name
          # servicePort: 8080

    # Example of a wildcard subdomain
    - host: dojo-portal.az-rnd.ephico2real.com
      annotations:
        haproxy.router.openshift.io/timeout: 60s
      tls:
        enabled: true
        secretName: wildcard-az-rnd-tls-secret
      paths:
        - path: /
          pathType: Prefix
          
    # You can add more hosts as needed
    - host: api.az-rnd.ephico2real.com
      tls:
        enabled: true
        secretName: wildcard-az-rnd-tls-secret
      paths:
        - path: /
          pathType: Prefix
          serviceName: api-service
          servicePort: 8080
```

## templates/_helpers.tpl

```tpl
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
Create the name of the service account to use
*/}}
{{- define "openshift-ingress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openshift-ingress.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## templates/ingress.yaml

```yaml
{{- if .Values.ingress.enabled }}
{{- $fullName := include "openshift-ingress.fullname" . -}}
{{- $svcPort := .Values.service.port -}}
{{- range .Values.ingress.hosts }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}-{{ .host | replace "." "-" }}
  labels:
    {{- include "openshift-ingress.labels" $ | nindent 4 }}
    {{- with $.Values.ingress.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- if $.Values.ingress.className }}
    kubernetes.io/ingress.class: {{ $.Values.ingress.className }}
    {{- end }}
    {{- if .tls }}
    {{- if .tls.enabled }}
    kubernetes.io/tls-acme: "true"
    {{- end }}
    {{- end }}
    {{- with .annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- with $.Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if $.Values.ingress.openshiftRouterAnnotations }}
    # OpenShift-specific router annotations
    {{- with $.Values.ingress.openshiftRouterAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- end }}
spec:
  {{- if $.Values.ingress.className }}
  ingressClassName: {{ $.Values.ingress.className }}
  {{- end }}
  {{- if .tls }}
  {{- if .tls.enabled }}
  tls:
    - hosts:
        - {{ .host | quote }}
      {{- if .tls.secretName }}
      secretName: {{ .tls.secretName }}
      {{- else }}
      secretName: {{ $fullName }}-{{ .host | replace "." "-" }}-tls
      {{- end }}
  {{- end }}
  {{- end }}
  rules:
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ default "Prefix" .pathType }}
            backend:
              service:
                name: {{ default $fullName .serviceName }}
                port:
                  number: {{ default $svcPort .servicePort }}
          {{- end }}
{{- end }}
{{- end }}
```

## templates/serviceaccount.yaml

```yaml
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "openshift-ingress.serviceAccountName" . }}
  labels:
    {{- include "openshift-ingress.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
```

## templates/NOTES.txt

```
Thank you for installing {{ .Chart.Name }}.

The Ingress configuration has been applied with the following settings:

{{- if .Values.ingress.enabled }}
{{- range .Values.ingress.hosts }}
1. Host: {{ .host }}
   {{- range .paths }}
   Path: {{ .path }}
   {{- if .serviceName }}
   Service: {{ .serviceName }}
   {{- else }}
   Service: {{ include "openshift-ingress.fullname" $ }}
   {{- end }}
   {{- if .servicePort }}
   Port: {{ .servicePort }}
   {{- else }}
   Port: {{ $.Values.service.port }}
   {{- end }}
   {{- end }}
   {{- if .tls }}
   {{- if .tls.enabled }}
   TLS Secret: {{ .tls.secretName }}
   {{- end }}
   {{- end }}
{{- end }}
{{- else }}
Ingress is disabled. To enable it, set ingress.enabled to true in your values file.
{{- end }}

To verify the Ingress resources:
  kubectl get ingress -l app.kubernetes.io/instance={{ .Release.Name }}

To check for the generated OpenShift routes:
  oc get routes -l app.kubernetes.io/instance={{ .Release.Name }}
```

## README.md

```markdown
# OpenShift Ingress Helm Chart

This Helm chart deploys Ingress resources in OpenShift that are automatically converted to OpenShift Routes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- OpenShift 4.X with ingress controller configured

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release ./openshift-ingress-chart
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the fully qualified app name | `""` |
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.annotations` | Annotations for the service account | `{}` |
| `serviceAccount.name` | Name of the service account | `""` |
| `service.port` | Port of the default service | `3000` |
| `ingress.enabled` | Enable ingress resource | `true` |
| `ingress.className` | Ingress class name | `"openshift-default"` |
| `ingress.annotations` | Common annotations for all ingress resources | `{}` |
| `ingress.openshiftRouterAnnotations` | OpenShift router-specific annotations | See values.yaml |
| `ingress.labels` | Common labels for all ingress resources | See values.yaml |
| `ingress.hosts` | List of host configurations | See values.yaml |

## Usage

### Basic Example

```yaml
ingress:
  enabled: true
  hosts:
    - host: myapp.example.com
      tls:
        enabled: true
        secretName: myapp-tls-secret
      paths:
        - path: /
          pathType: Prefix
```

### Example with Multiple Services

```yaml
ingress:
  enabled: true
  hosts:
    - host: frontend.example.com
      tls:
        enabled: true
        secretName: frontend-tls-secret
      paths:
        - path: /
          pathType: Prefix
          serviceName: frontend
          servicePort: 80
    - host: api.example.com
      tls:
        enabled: true
        secretName: api-tls-secret
      paths:
        - path: /
          pathType: Prefix
          serviceName: api
          servicePort: 8080
```

### Example with OpenShift Router Annotations

```yaml
ingress:
  enabled: true
  openshiftRouterAnnotations:
    haproxy.router.openshift.io/timeout: 30s
    route.openshift.io/termination: edge
  hosts:
    - host: myapp.example.com
      annotations:
        haproxy.router.openshift.io/rate-limit-connections: 'true'
      tls:
        enabled: true
        secretName: myapp-tls-secret
      paths:
        - path: /
          pathType: Prefix
```

## Notes

- This chart creates Ingress resources that are automatically converted to OpenShift Routes
- All OpenShift router annotations can be configured through the values file
- Per-host annotations will override global annotations
```
# openshift-ingress-chart
