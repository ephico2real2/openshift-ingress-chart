# OpenShift Ingress Helm Chart

This Helm chart deploys Ingress resources in OpenShift that are automatically converted to OpenShift Routes.

## Architecture

This chart implements a clear separation between global defaults and specific overrides:

- **Global Configuration**: Common settings applied to all ingress resources
- **Host-Specific Configuration**: Settings that apply to a specific host, overriding globals
- **Path-Specific Configuration**: Settings that apply to a specific path, overriding both host and global settings

This hierarchy ensures that the most specific configuration takes precedence.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- OpenShift 4.X with ingress controller configured

## Installing the Chart

To install the chart with the release name `my-release`:

```bash

helm template --dry-run --debug test-install . -f ../test-values/simple.yaml

helm template --dry-run --debug test-install . -f ./values.yaml

helm install my-release ./openshift-ingress-chart

```

## Configuration

### Global Settings

The global section defines default settings applied to all hosts unless overridden:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.service.port` | Default port for all services | `3000` |
| `global.tls.enabled` | Enable TLS by default | `true` |
| `global.tls.secretNamePrefix` | Prefix for auto-generated TLS secret names | `""` |
| `global.ingressClassName` | Ingress controller class | `"openshift-default"` |
| `global.annotations` | Common annotations for all ingress resources | `{}` |
| `global.openshiftAnnotations` | OpenShift-specific annotations | See values.yaml |
| `global.labels` | Common labels for all ingress resources | See values.yaml |
| `global.path` | Default path | `"/"` |
| `global.pathType` | Default path type | `"Prefix"` |

### Host Configuration

Each host can override global settings:

```yaml
ingress:
  enabled: true
  hosts:
    - host: example.com
      annotations: {}  # Host-specific annotations (overrides globals)
      tls:
        enabled: true  # Overrides global.tls.enabled
        secretName: "example-tls"  # Overrides auto-generated name
      service:
        name: "example-svc"  # Overrides default service name
        port: 8080  # Overrides global.service.port
      paths:
        - path: "/"  # Overrides global.path
          pathType: "Prefix"  # Overrides global.pathType
          service:
            name: "example-path-svc"  # Overrides host service name
            port: 9090  # Overrides host service port
```

### Precedence Rules

Values are selected with the following precedence (highest to lowest):

1. Path-specific configuration
2. Host-specific configuration
3. Global configuration
4. Built-in defaults

## Examples

### Basic Example with Global Defaults

```yaml
global:
  service:
    port: 8080
  tls:
    enabled: true
    secretNamePrefix: "myapp"
  ingressClassName: "openshift-default"
  
ingress:
  enabled: true
  hosts:
    - host: example.com
    - host: api.example.com
```

### Multiple Hosts with Specific Overrides

```yaml
global:
  service:
    port: 3000
  
ingress:
  enabled: true
  hosts:
    - host: frontend.example.com
      service:
        name: frontend
    - host: api.example.com
      service:
        name: backend
        port: 8080
      annotations:
        haproxy.router.openshift.io/timeout: 60s
```

### Advanced Example with Multiple Paths

```yaml
ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /api
          service:
            name: api-service
            port: 8080
        - path: /
          service:
            name: frontend-service
            port: 3000
```

## TLS Certificate Management

This chart provides multiple options for managing TLS certificates:

### Option 1: Manually provide certificates in values

You can specify certificates directly in the values file:

```yaml
tls:
  certificates:
    example-com-tls:
      cert: |
        -----BEGIN CERTIFICATE-----
        [YOUR BASE64 CERTIFICATE DATA HERE]
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        [YOUR BASE64 PRIVATE KEY DATA HERE]
        -----END PRIVATE KEY-----
```

### Option 2: Use cert-manager integration

If you have cert-manager installed in your cluster, enable it to automatically issue and manage certificates:

```yaml
certManager:
  enabled: true
  issuerName: "letsencrypt-prod"
  issuerKind: "ClusterIssuer"
  # Include wildcard subdomain in the certificate
  includeWildcard: false
```

### Option 3: Generate self-signed certificates using the included script

The chart includes a utility script to generate self-signed certificates for development/testing:

```bash
# Navigate to the scripts directory
cd scripts

# Generate certificates for all hosts defined in values.yaml
./generate-tls-secrets.sh ../values.yaml default
```

## Notes

- This chart creates Ingress resources that are automatically converted to OpenShift Routes
- All OpenShift router annotations can be configured through the values file
- The chart implements a clear precedence hierarchy: path-specific > host-specific > global
- Resource names are automatically truncated to comply with Kubernetes' 63-character limit
- Long domain names in hosts will be properly handled by truncating the resulting resource names while maintaining the actual hostnames
