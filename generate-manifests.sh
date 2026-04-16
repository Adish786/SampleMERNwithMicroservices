#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="${1:-${SCRIPT_DIR}/k8s-manifests}"

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: ./generate-manifests.sh [output-directory]

Generates the Kubernetes manifests into the given directory.
If no directory is provided, the script writes to ./k8s-manifests.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

trap 'printf "Manifest generation failed near line %s\n" "$LINENO" >&2' ERR

mkdir -p "${OUTPUT_DIR}"

cat > "${OUTPUT_DIR}/mongodb-secret.yaml" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
data:
  mongodb-root-username: YWRtaW4=      # base64 of "admin"
  mongodb-root-password: cGFzc3dvcmQ=  # base64 of "password"
EOF

cat > "${OUTPUT_DIR}/mongodb-service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  clusterIP: None
  selector:
    app: mongodb
  ports:
    - port: 27017
      targetPort: 27017
EOF

cat > "${OUTPUT_DIR}/mongodb-statefulset.yaml" <<'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb-service
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:latest
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongodb-root-username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongodb-root-password
          volumeMounts:
            - name: mongodb-storage
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongodb-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
EOF

cat > "${OUTPUT_DIR}/hello-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-service
  labels:
    app: hello-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-service
  template:
    metadata:
      labels:
        app: hello-service
    spec:
      containers:
        - name: hello-service
          image: REGION-docker.pkg.dev/YOUR_PROJECT_ID/mern-app-repo/hello-service:latest
          ports:
            - containerPort: 3001
          env:
            - name: PORT
              value: "3001"
            # Add any other environment variables your helloService needs
            # For example, if it connects to MongoDB, add:
            # - name: MONGO_URI
            #   value: "mongodb://mongodb-0.mongodb-service.default.svc.cluster.local:27017"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  selector:
    app: hello-service
  ports:
    - protocol: TCP
      port: 3001
      targetPort: 3001
  type: ClusterIP
EOF

cat > "${OUTPUT_DIR}/profile-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: profile-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: profile-service
  template:
    metadata:
      labels:
        app: profile-service
    spec:
      containers:
        - name: profile-service
          image: YOUR_REGION-docker.pkg.dev/YOUR_PROJECT/mern-repo/profile-service:latest
          ports:
            - containerPort: 3002
          env:
            - name: PORT
              value: "3002"
            - name: MONGO_URL
              value: "mongodb://$(MONGODB_USERNAME):$(MONGODB_PASSWORD)@mongodb-service.default.svc.cluster.local:27017"
            - name: MONGODB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongodb-root-username
            - name: MONGODB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: mongodb-root-password
---
apiVersion: v1
kind: Service
metadata:
  name: profile-service
spec:
  selector:
    app: profile-service
  ports:
    - port: 3002
      targetPort: 3002
  type: ClusterIP
EOF

cat > "${OUTPUT_DIR}/frontend-deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: YOUR_REGION-docker.pkg.dev/YOUR_PROJECT/mern-repo/frontend:latest
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - port: 3000
      targetPort: 3000
  type: ClusterIP
EOF

cat > "${OUTPUT_DIR}/ingress.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mern-ingress
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 3000
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: hello-service
                port:
                  number: 3001
          - path: /profile
            pathType: Prefix
            backend:
              service:
                name: profile-service
                port:
                  number: 3002
EOF

if command -v kubectl >/dev/null 2>&1; then
  if kubectl apply --dry-run=client -f "${OUTPUT_DIR}" >/dev/null; then
    log "Manifests generated and validated in ${OUTPUT_DIR}"
  else
    log "Manifests generated in ${OUTPUT_DIR}, but kubectl validation failed."
    exit 1
  fi
else
  log "kubectl not found; manifests generated in ${OUTPUT_DIR}"
fi
