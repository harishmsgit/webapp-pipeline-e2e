# Sprint 5: Monitoring Setup with Prometheus, Grafana, and Jenkins Alerts

## Objective
Implement production-grade observability for application and infrastructure using Prometheus and Grafana in EKS, with Jenkins-integrated alerting for failed deployments and critical health signals.

## Scope
  - Kubernetes node and workload metrics
  - application metrics from `webapp`
  - application latency, request rate, error rate
  - pod health, restart trends, CPU and memory
  - cluster and node resource signals
  - monitoring validation stage after deployment
  - alert notifications on deployment/health failures
  - app down/unavailable
  - high pod restarts
  - high CPU and memory utilization
  - node readiness risk

## Implementation Plan
1. Expose app metrics endpoint (`/metrics`) in Node.js app.
2. Add monitoring manifests under `monitoring/`:
3. Extend Sprint 4 deployment pipeline (`Jenkinsfile.sprint4`) with:
4. Validate end-to-end:

## Deliverables

## Success Criteria

## Operational Notes

For the full step-by-step setup and command guide, see [Docs/sprint5-prometheus-grafana-end-to-end.md](Docs/sprint5-prometheus-grafana-end-to-end.md).
