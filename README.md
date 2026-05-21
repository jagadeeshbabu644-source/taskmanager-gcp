# Task Manager — GCP Deployment

## Architecture
- **App**: Java Spring Boot (REST API + HTML/JS UI)
- **Container**: Docker on GKE single-zone (us-central1-a)
- **Node type**: e2-medium (2 vCPU, 1 GB RAM)
- **Load Balancer**: GCP HTTP(S) Load Balancer
- **IaC**: Terraform + Terragrunt
- **CI/CD**: Google Cloud Build (GitOps)
- **Observability**: Cloud Logging + Cloud Monitoring
  + Prometheus + Grafana OSS

## Grafana Dashboard Panels
1. Traffic (RPS) — requests per second
2. Error Rate (%) — percentage of 5xx responses
3. P95 Latency (ms) — 95th percentile response time

## SRE Fundamentals

### Service Level Indicators (SLIs)

**1. Availability SLI**
Definition: Percentage of HTTP requests that return
a non-5xx response over a 5-minute window.

Measured by (PromQL):
(
sum(rate(http_server_requests_seconds_count{status!~"5.."}[5m]))
/
sum(rate(http_server_requests_seconds_count[5m]))
) * 100

**2. Latency SLI**
Definition: Percentage of HTTP requests that complete
within 300ms over a 5-minute window.

Measured by (PromQL):
(
sum(rate(http_server_requests_seconds_bucket{le="0.3"}[5m]))
/
sum(rate(http_server_requests_seconds_count[5m]))
) * 100
### Service Level Objective (SLO)

**Availability SLO**
- Target: 99.5% of requests succeed over a 30-day window
- Error Budget: 0.5% = ~3.6 hours downtime per month
- Meaning: If more than 0.5% of requests fail in a month,
  the SLO is breached and the team must prioritize fixes
  over new features

| SLI         | Target | Window  | Error Budget     |
|-------------|--------|---------|------------------|
| Availability| 99.5%  | 30 days | ~3.6 hrs/month   |
| Latency P95 | 95%    | 30 days | 5% of requests   |
| Latency P99 | 99%    | 7 days  | 1% of requests   |

## Capacity Assumptions
- GKE: 1-3 nodes (e2-medium: 2 vCPU, 1 GB RAM each)
- HPA: min 2 replicas, max 8, scales at 70% CPU
- Memory per pod: 256 MB request, 512 MB limit
- Expected traffic: ~500 RPS steady, ~2000 RPS peak

## GitOps Flow

The desired state of the system is defined in Git.
GitHub is the single source of truth.
Cloud Build ensures GKE always matches GitHub.
Developer creates feature branch
|
v
Opens Pull Request on GitHub
|
v
Cloud Build Trigger 1 fires (cloudbuild-pr.yaml)
-> Builds JAR + verifies Docker image
-> Does NOT deploy to GKE
-> GitHub shows: check passed ✅
|
v
Code review and approval
|
v
PR merged to main
|
v
Cloud Build Trigger 2 fires (cloudbuild-main.yaml)
-> Build JAR
-> Build + push Docker image to Artifact Registry
-> kubectl apply all K8s manifests
-> kubectl set image (new commit SHA tag)
-> kubectl rollout status (verify healthy)
|
v
New version live in ~8-10 minutes

Rollback: git revert -> merge -> Cloud Build redeploys

## Branch Protection
- Require PR before merging to main
- Require Cloud Build check to pass
- No direct pushes to main allowed

## Sensitive Info Handling
- Project ID: TF_VAR_project_id env var (not in any file)
- terraform.tfvars: in .gitignore (never committed)
- cloudbuild yaml: uses $PROJECT_ID (GCP auto-injects)

## Repository Structure
app/                  Java Spring Boot source + Dockerfile
k8s/                  Kubernetes manifests
terraform/
modules/            Reusable Terraform modules
environments/       Terragrunt configs (prod)
monitoring/           Grafana dashboard JSON export
cloudbuild-pr.yaml    Cloud Build: PR validation only
cloudbuild-main.yaml  Cloud Build: full deploy on merge
README.md             This file
