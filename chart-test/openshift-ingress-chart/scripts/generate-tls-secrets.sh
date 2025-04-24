#\!/bin/bash
#
# Script to generate self-signed certificates and create TLS secrets for the ingress hosts
# 
# Usage: ./generate-tls-secrets.sh [values-file] [namespace]
#   values-file: Path to the values file (default: ../values.yaml)
#   namespace: Kubernetes namespace where to create the secrets (default: default)
#
# Requirements:
#   - openssl
#   - kubectl
#   - yq (https://github.com/mikefarah/yq)

set -e

VALUES_FILE=${1:-"../values.yaml"}
NAMESPACE=${2:-"default"}
CERT_DIR="./.tmp-certs"

if \! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed"
    exit 1
fi

if \! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

if \! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Install with: brew install yq"
    exit 1
fi

# Create temp directory for certificates
mkdir -p "$CERT_DIR"

# Extract global settings
TLS_ENABLED=$(yq '.global.tls.enabled' "$VALUES_FILE")
SECRET_PREFIX=$(yq '.global.tls.secretNamePrefix' "$VALUES_FILE")

if [ "$TLS_ENABLED" \!= "true" ]; then
    echo "TLS is not enabled globally. Checking individual hosts..."
fi

# Get all hosts from the values file
echo "Parsing hosts from $VALUES_FILE..."
HOST_COUNT=$(yq '.ingress.hosts | length' "$VALUES_FILE")

for ((i=0; i<$HOST_COUNT; i++)); do
    HOST=$(yq ".ingress.hosts[$i].host" "$VALUES_FILE")
    HOST_TLS_ENABLED=$(yq ".ingress.hosts[$i].tls.enabled // \"$TLS_ENABLED\"" "$VALUES_FILE")
    HOST_SECRET_NAME=$(yq ".ingress.hosts[$i].tls.secretName" "$VALUES_FILE")
    
    if [ "$HOST_TLS_ENABLED" \!= "true" ]; then
        echo "Skipping $HOST - TLS not enabled"
        continue
    fi
    
    # Format hostname for secret naming
    FORMATTED_HOST=$(echo "$HOST" | tr '.' '-')
    
    # Determine secret name
    if [ "$HOST_SECRET_NAME" \!= "null" ]; then
        SECRET_NAME="$HOST_SECRET_NAME"
    elif [ -n "$SECRET_PREFIX" ]; then
        SECRET_NAME="${SECRET_PREFIX}-${FORMATTED_HOST}-tls"
    else
        SECRET_NAME="${FORMATTED_HOST}-tls"
    fi
    
    # Truncate to 63 chars if needed (Kubernetes limit)
    if [ ${#SECRET_NAME} -gt 63 ]; then
        SECRET_NAME="${SECRET_NAME:0:63}"
        # Remove trailing dash if present
        SECRET_NAME="${SECRET_NAME%-}"
    fi
    
    echo "Generating certificate for: $HOST (Secret: $SECRET_NAME)"
    
    # Generate private key
    openssl genrsa -out "$CERT_DIR/$HOST.key" 2048
    
    # Generate CSR configuration
    cat > "$CERT_DIR/$HOST.cnf" << CONF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = $HOST

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $HOST
DNS.2 = *.$HOST
CONF
    
    # Generate CSR
    openssl req -new -key "$CERT_DIR/$HOST.key" -out "$CERT_DIR/$HOST.csr" -config "$CERT_DIR/$HOST.cnf"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "$CERT_DIR/$HOST.csr" -signkey "$CERT_DIR/$HOST.key" -out "$CERT_DIR/$HOST.crt" \
        -extensions v3_req -extfile "$CERT_DIR/$HOST.cnf"
    
    # Create kubernetes secret
    echo "Creating Kubernetes secret: $SECRET_NAME"
    kubectl create secret tls "$SECRET_NAME" \
        --cert="$CERT_DIR/$HOST.crt" \
        --key="$CERT_DIR/$HOST.key" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "Secret $SECRET_NAME created for $HOST"
    echo "-------------------------"
done

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$CERT_DIR"

echo "TLS secrets generation complete."
