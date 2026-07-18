# Sprint 5: Monitoring Setup with Prometheus, Grafana, and Jenkins Alerts

## Objective
Implement production-grade observability for application and infrastructure using Prometheus and Grafana in EKS, with Jenkins-integrated alerting for failed deployments and critical health signals.

## Scope
- Prometheus installed in EKS and collecting:
  - Kubernetes node and workload metrics
  - application metrics from `webapp`
- Grafana configured with dashboards for:
  - application latency, request rate, error rate
  - pod health, restart trends, CPU and memory
  - cluster and node resource signals
- Jenkins integration:
  - monitoring validation stage after deployment
  - alert notifications on deployment/health failures
- Prometheus alerting rules:
  - app down/unavailable
  - high pod restarts
  - high CPU and memory utilization
  - node readiness risk

## Implementation Plan
1. Expose app metrics endpoint (`/metrics`) in Node.js app.
2. Add monitoring manifests under `monitoring/`:
- ServiceMonitor for webapp
- PrometheusRule alert policies
- Grafana dashboard ConfigMap
3. Extend Sprint 4 deployment pipeline (`Jenkinsfile.sprint4`) with:
- monitoring manifest apply stage
- monitoring health verification stage
- webhook/email-capable notification hooks
4. Validate end-to-end:
- Prometheus target discovery
- Grafana dashboard availability
- alert rule presence
- Jenkins notifications on forced failure scenario

## Deliverables
- `monitoring/service-monitor-webapp.yaml`
- `monitoring/prometheus-rules-webapp.yaml`
- `monitoring/grafana-dashboard-webapp.yaml`
- `Docs/sprint5-monitoring-Prometheus-Grafana.md`
- updates to `Jenkinsfile.sprint4`, `app/server.js`, and Kubernetes manifests as required

## Success Criteria
- Prometheus scrapes `webapp` metrics endpoint successfully.
- Grafana dashboard shows live app and resource metrics.
- Alert rules are loaded and visible in Prometheus.
- Jenkins emits notifications for deployment/health failures.
- Monitoring checks pass in pipeline post-deployment stage.

## Operational Notes
- Monitoring namespace: `monitoring`
- Application namespace: `webapp`
- Kubernetes CRDs expected from `kube-prometheus-stack` Helm release
- Alert delivery endpoint can be provided via Jenkins parameter (webhook URL)
