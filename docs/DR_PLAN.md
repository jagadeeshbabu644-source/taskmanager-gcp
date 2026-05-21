# Disaster Recovery Plan — Task Manager Application

## Overview
This document defines the end-to-end DR plan for the
Task Manager application deployed on GCP GKE.
The application is treated as business-critical.

## Architecture: Active / Passive
PRIMARY REGION (us-central1) — ACTIVE
GKE Cluster: taskmanager-cluster
Zone: us-central1-a
Replicas: 2 (min) via HPA
Status: Serving all live traffic
DR REGION (us-east1) — PASSIVE
GKE Cluster: taskmanager-cluster-dr
Zone: us-east1-b
Replicas: 1 (warm standby)
Status: Running but receiving no traffic
Global HTTP(S) Load Balancer
Primary backend: us-central1 (active)
DR backend: us-east1 (ready, no traffic)
Health checks: every 10 seconds
Failover: automatic when primary fails 3 checks

## RTO (Recovery Time Objective)

**Target RTO: 15 minutes**

| Phase | Action | Time |
|-------|--------|------|
| Detection | Cloud Monitoring alert fires | 2 min |
| Triage | On-call confirms failure | 3 min |
| DNS Failover | TTL expires, points to DR | 1 min |
| LB Switch | Global LB routes to DR | 2 min |
| DR Scale-up | HPA scales DR 1 -> 3 replicas | 5 min |
| Validation | Health checks pass | 2 min |
| **TOTAL** | | **15 min** |

## RPO (Recovery Point Objective)

**Target RPO: 1 hour**

| Data Type | Storage | Replication | RPO |
|-----------|---------|-------------|-----|
| Task data | In-memory | None (stateless) | Data loss on restart |
| App config | Git + ConfigMaps | Git commits | 0 |
| Docker images | Artifact Registry | Multi-region | 0 |
| Terraform state | GCS bucket | GCS versioning | 0 |
| Logs | Cloud Logging | Streaming | < 1 min |

Note: Current app is stateless (in-memory storage).
In production, a Cloud SQL database with async
replication would reduce RPO to near zero.

## Failover Runbook

### Step 1: Declare Incident
```bash
# Check primary cluster health
kubectl get pods -n taskmanager

# Check LB backend health
gcloud compute backend-services get-health \
  taskmanager-backend --global

# Notify: Engineering Lead + Product Manager
```

### Step 2: Activate DR Cluster
```bash
DR_CTX="gke_PROJECT_ID_us-east1-b_taskmanager-cluster-dr"

# Scale DR from 1 to 3 replicas
kubectl scale deployment taskmanager \
  --replicas=3 \
  -n taskmanager \
  --context=$DR_CTX

# Wait for DR pods
kubectl rollout status deployment/taskmanager \
  -n taskmanager \
  --context=$DR_CTX

# Smoke test
DR_IP="<DR_LOAD_BALANCER_IP>"
curl -f http://$DR_IP/health
```

### Step 3: Switch Traffic to DR
```bash
# Update DNS to DR Load Balancer IP
gcloud dns record-sets update taskmanager.example.com \
  --type=A \
  --ttl=60 \
  --rrdatas=$DR_IP \
  --zone=your-dns-zone

# Verify DNS propagated
nslookup taskmanager.example.com
curl https://taskmanager.example.com/health
```

### Step 4: Validate DR is Serving
```bash
# Confirm app responding
curl https://taskmanager.example.com/api/stats

# Monitor DR cluster
kubectl top pods -n taskmanager --context=$DR_CTX
kubectl get hpa  -n taskmanager --context=$DR_CTX
```

### Step 5: Failback to Primary
```bash
PRIMARY_CTX="gke_PROJECT_ID_us-central1-a_taskmanager-cluster"

# Fix root cause in primary
# Redeploy to primary
kubectl apply -f k8s/ --context=$PRIMARY_CTX
kubectl rollout status deployment/taskmanager \
  -n taskmanager \
  --context=$PRIMARY_CTX

# Switch DNS back to primary
gcloud dns record-sets update taskmanager.example.com \
  --type=A \
  --ttl=60 \
  --rrdatas=<PRIMARY_LB_IP> \
  --zone=your-dns-zone

# Scale DR back to warm standby
kubectl scale deployment taskmanager \
  --replicas=1 \
  -n taskmanager \
  --context=$DR_CTX

# Write postmortem within 48 hours
```

## Backup Guidelines

| Asset | Method | Frequency | Retention |
|-------|--------|-----------|-----------|
| Terraform state | GCS versioning | Every apply | 90 versions |
| K8s manifests | Git repo | Every commit | Indefinite |
| Docker images | Artifact Registry | Every build | 30 days |
| App config | Git + ConfigMaps | Every change | Indefinite |
| Cloud Logs | GCS log sink | Streaming | 90 days |
| Grafana dashboards | Git JSON export | Every change | Indefinite |

## Quarterly DR Drill

Schedule: First Sunday of every quarter, 2 AM IST
Duration: 2 hours
Steps:
  1. Scale primary to 0 replicas (simulate failure)
  2. Execute failover runbook Steps 1-4
  3. Measure actual RTO (target < 15 min)
  4. Failback to primary
  5. Document results and update runbook
