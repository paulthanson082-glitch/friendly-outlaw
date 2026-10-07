# Google Cloud Code Integration Guide

Deploy and manage friendly-outlaw on Google Cloud Platform.

## What is Google Cloud Code?

Google Cloud Code provides:
- Local development with cloud debugging
- Kubernetes and Cloud Run deployment
- Container development (Docker)
- GCP resource management
- IDE integration (VS Code, JetBrains)

---

## Setup Steps

### 1. Install Google Cloud SDK

```bash
# macOS
brew install --cask google-cloud-sdk

# Or: https://cloud.google.com/sdk/docs/install

# Verify
gcloud --version
```

### 2. Authenticate with GCP

```bash
gcloud init                                    # Interactive setup
gcloud auth application-default login          # Set default credentials
gcloud config set project friendly-outlaw-xyz  # Set project
```

### 3. Install Cloud Code Extension

In VS Code:
- Go to Extensions (`Cmd+Shift+X`)
- Search "Google Cloud Code"
- Click Install

Or command line:
```bash
code --install-extension googlecloudtools.cloudcode
```

---

## Deploy Options

### Option A: Cloud Run (Recommended for CLI)

Fast serverless deployment:

```bash
# 1. Create Dockerfile
cat > Dockerfile << 'EOF'
FROM swift:5.9

WORKDIR /app
COPY . .

RUN swift build -c release

EXPOSE 8080
CMD ["swift", "run", "-c", "release", "WritersAppCLI"]
EOF

# 2. Build and deploy
gcloud run deploy friendly-outlaw \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY

# 3. Get URL
gcloud run services describe friendly-outlaw --region us-central1
```

### Option B: Cloud Build (CI/CD)

Automated builds from git:

```bash
# 1. Create cloudbuild.yaml
cat > cloudbuild.yaml << 'EOF'
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/friendly-outlaw', '.']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/friendly-outlaw']

  - name: 'gcr.io/cloud-builders/run'
    args:
      - 'deploy'
      - 'friendly-outlaw'
      - '--image=gcr.io/$PROJECT_ID/friendly-outlaw'
      - '--region=us-central1'
      - '--platform=managed'

images:
  - 'gcr.io/$PROJECT_ID/friendly-outlaw'

env:
  - 'ANTHROPIC_API_KEY=$_ANTHROPIC_API_KEY'

substitutions:
  _ANTHROPIC_API_KEY: 'sk-ant-...'
EOF

# 2. Submit build
gcloud builds submit --config cloudbuild.yaml
```

### Option C: Google Kubernetes Engine (GKE)

For scalable deployments:

```bash
# 1. Create cluster
gcloud container clusters create friendly-outlaw-cluster \
  --num-nodes=2 \
  --machine-type=n1-standard-1

# 2. Configure kubectl
gcloud container clusters get-credentials friendly-outlaw-cluster

# 3. Create Kubernetes deployment
cat > k8s-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: friendly-outlaw
spec:
  replicas: 3
  selector:
    matchLabels:
      app: friendly-outlaw
  template:
    metadata:
      labels:
        app: friendly-outlaw
    spec:
      containers:
      - name: app
        image: gcr.io/PROJECT_ID/friendly-outlaw
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: api-keys
              key: anthropic
        ports:
        - containerPort: 8080
EOF

# 4. Deploy
kubectl apply -f k8s-deployment.yaml

# 5. Expose service
kubectl expose deployment friendly-outlaw \
  --type LoadBalancer \
  --port 80 \
  --target-port 8080
```

---

## Development Workflow

### Local Development with Cloud Services

```bash
# 1. Start local development with Cloud Debugger
gcloud run deploy friendly-outlaw \
  --source . \
  --local-debugging \
  --allow-unauthenticated

# 2. Connect Debugger
# In VS Code: Cloud Code > Debug on Cloud Run (local)

# 3. Set breakpoints in VS Code and debug in real-time
```

### Use Cloud Logging

```bash
# View logs
gcloud run services logs read friendly-outlaw

# Stream logs in real-time
gcloud run services logs read friendly-outlaw --stream

# Filter by severity
gcloud run services logs read friendly-outlaw --filter "severity:ERROR"
```

---

## Cloud SQL Integration

Store data in managed PostgreSQL/MySQL:

```bash
# 1. Create Cloud SQL instance
gcloud sql instances create friendly-outlaw-db \
  --database-version POSTGRES_15 \
  --tier db-f1-micro

# 2. Create database
gcloud sql databases create writersapp \
  --instance=friendly-outlaw-db

# 3. Get connection details
CLOUD_SQL_INSTANCE=$(gcloud sql instances describe friendly-outlaw-db --format='value(connectionName)')

# 4. Update DatabaseManager to use Cloud SQL
# Modify Package.swift or environment config to point to Cloud SQL
```

---

## Cloud Firestore for Real-Time Sync

Enable real-time document synchronization:

```swift
// Example: WritersApp with Firestore
import FirebaseFirestore

extension DocumentManager {
    func syncWithFirestore() async throws {
        let db = Firestore.firestore()

        for document in self.documents {
            try await db.collection("documents")
                .document(document.id.uuidString)
                .setData(document.toDictionary())
        }
    }
}
```

---

## Cloud Storage for Exports

Store document exports in Cloud Storage:

```bash
# 1. Create bucket
gsutil mb gs://friendly-outlaw-exports

# 2. Upload documents
gsutil cp export.md gs://friendly-outlaw-exports/

# 3. Generate signed URLs for sharing
gsutil signurl ~/.gcloud/credentials.json gs://friendly-outlaw-exports/export.md

# 4. In code:
# Use google-cloud-swift SDK to upload from app
```

---

## Vertex AI Integration (Advanced AI Features)

Use Google's AI models in addition to Claude:

```bash
# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Create service account
gcloud iam service-accounts create friendly-outlaw-ai

# Grant permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:friendly-outlaw-ai@PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/aiplatform.user
```

---

## Monitoring & Alerting

### Set Up Dashboards

```bash
# Create monitoring dashboard
gcloud monitoring dashboards create --config='{
  "displayName": "Friendly Outlaw Dashboard",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Request Rate",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        }
      }
    ]
  }
}'
```

### Create Alerts

```bash
# Alert if error rate > 5%
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=5 \
  --condition-threshold-comparison=COMPARISON_GT \
  --condition-threshold-filter='resource.type="cloud_run_revision"'
```

---

## CI/CD Pipeline with Cloud Build

Automate testing and deployment:

```yaml
# cloudbuild.yaml - Advanced
steps:
  # Step 1: Run tests
  - name: 'gcr.io/cloud-builders/docker'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        docker build -t test-image --target test .
        docker run test-image swift test

  # Step 2: Security scanning
  - name: 'gcr.io/cloud-builders/gke-deploy'
    args:
      - run
      - --filename=.
      - --image=gcr.io/cloud-builders/gke-deploy
      - --location=us-central1
      - --cluster=friendly-outlaw-cluster

  # Step 3: Build production image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'gcr.io/$PROJECT_ID/friendly-outlaw:$COMMIT_SHA'
      - '.'

  # Step 4: Push to registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/friendly-outlaw:$COMMIT_SHA']

  # Step 5: Deploy
  - name: 'gcr.io/cloud-builders/run'
    args:
      - 'deploy'
      - 'friendly-outlaw'
      - '--image=gcr.io/$PROJECT_ID/friendly-outlaw:$COMMIT_SHA'
      - '--region=us-central1'

images:
  - 'gcr.io/$PROJECT_ID/friendly-outlaw:$COMMIT_SHA'

timeout: '1800s'
```

---

## Local Cloud Emulator Setup

Test against local cloud services:

```bash
# Install emulators
gcloud components install cloud-datastore-emulator

# Start emulator
gcloud beta emulators firestore start --host-port localhost:8081

# In another terminal, set environment:
export FIRESTORE_EMULATOR_HOST=localhost:8081

# Run app against local Firestore
swift run WritersAppCLI
```

---

## Cost Optimization Tips

### 1. Use Preemptible VMs
```bash
gcloud compute instances create friendly-outlaw-vm \
  --preemptible \
  --machine-type=n1-standard-1
```

### 2. Auto-scaling
```bash
gcloud run deploy friendly-outlaw \
  --min-instances=0 \
  --max-instances=100
```

### 3. Cold Start Optimization
```dockerfile
# Multi-stage build for smaller images
FROM swift:5.9 as builder
RUN apt-get install -y sqlite3-dev
WORKDIR /build
COPY . .
RUN swift build -c release

FROM debian:bookworm-slim
COPY --from=builder /build/.build/release/WritersAppCLI /app/
ENTRYPOINT ["/app/WritersAppCLI"]
```

---

## Quick Reference Commands

```bash
# Deploy
gcloud run deploy friendly-outlaw --source .

# View logs
gcloud run services logs read friendly-outlaw

# Update service
gcloud run deploy friendly-outlaw --update-env-vars KEY=VALUE

# Delete service
gcloud run services delete friendly-outlaw

# List all services
gcloud run services list

# Connect to Cloud SQL
gcloud cloud-sql-proxy friendly-outlaw-db &

# SSH into Compute Engine instance
gcloud compute ssh friendly-outlaw-vm
```

---

## Next Steps

1. **Set up authentication** → `gcloud auth application-default login`
2. **Create a Cloud Run service** → Copy & run Option A commands
3. **Enable Cloud Logging** → View logs in real-time
4. **Set up CI/CD** → Use cloudbuild.yaml
5. **Monitor performance** → Create monitoring dashboard

👉 **Start with:**
```bash
gcloud init
gcloud run deploy friendly-outlaw --source .
```
