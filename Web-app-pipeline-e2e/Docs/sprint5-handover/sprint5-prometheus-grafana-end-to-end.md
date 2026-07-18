# Sprint 5 End-to-End Guide: Prometheus and Grafana Monitoring

## 1. Purpose

This document explains how monitoring works in Sprint 5, where each component is configured, and which commands to use to install, validate, and operate the stack.

The goal is to provide a complete, understandable path from source code to monitoring dashboards and alerting:

- the application exposes Prometheus metrics
- Kubernetes scrapes the app and cluster metrics
- Grafana visualizes the metrics
- Jenkins verifies the monitoring stack and sends alerts on failures

## 2. Where Everything Is Set Up

### 2.1 Application Metrics

Location:
- [app/server.js](../app/server.js)
- [app/package.json](../app/package.json)

What it does:
- exposes `/metrics`
- exposes `/healthz`
- tracks request count and request duration using `prom-client`

### 2.2 Kubernetes Application Manifests

Location:
- [k8s/deployment.yaml](../k8s/deployment.yaml)
- [k8s/service.yaml](../k8s/service.yaml)
- [k8s/namespace.yaml](../k8s/namespace.yaml)

What it does:
- deploys the web app into the `webapp` namespace
- exposes a `metrics` service port on `3000`
- adds Prometheus scrape annotations to the pod template

### 2.3 Monitoring Resources

Location:
- [monitoring/service-monitor-webapp.yaml](../monitoring/service-monitor-webapp.yaml)
- [monitoring/prometheus-rules-webapp.yaml](../monitoring/prometheus-rules-webapp.yaml)
- [monitoring/grafana-dashboard-webapp.yaml](../monitoring/grafana-dashboard-webapp.yaml)

What it does:
- tells Prometheus which app service to scrape
- defines alert rules for app and cluster health
- loads a Grafana dashboard for the web app

### 2.4 Jenkins Monitoring Flow

Location:
- [Jenkinsfile.sprint5](../Jenkinsfile.sprint5)

What it does:
- deploys the app to EKS
- bootstraps `kube-prometheus-stack` if CRDs are missing
- applies the monitoring manifests
- validates Prometheus/Grafana readiness
- sends optional webhook alerts for success/failure

### 2.5 Terraform Monitoring Bootstrap

Location:
- [terraform/main.tf](../terraform/main.tf)

What it does:
- provisions Prometheus/Grafana through Helm during infrastructure provisioning
- creates the `monitoring` namespace
- sets Grafana admin password for bootstrap

## 3. What Is Installed Where

### 3.1 EKS Cluster

Installed in the cluster:
- `webapp` namespace for the app
- `monitoring` namespace for Prometheus and Grafana
- `kube-prometheus-stack` Helm release
- Prometheus CRDs
- Grafana dashboard ConfigMap
- Prometheus alert rules

### 3.2 Application Namespace

Namespace:
- `webapp`

Contains:
- `Deployment`
- `Service`
- `HorizontalPodAutoscaler`

### 3.3 Monitoring Namespace

Namespace:
- `monitoring`

Contains:
- Prometheus
- Grafana
- ServiceMonitor
- PrometheusRule
- dashboard ConfigMap

### 3.4 Jenkins

Jenkins is used to:
- deploy the application
- bootstrap monitoring if it is not already installed
- verify monitoring resources
- notify on failure through webhook-based alerts

## 4. End-to-End Flow

1. Developer commits code.
2. Jenkins runs [Jenkinsfile.sprint5](../Jenkinsfile.sprint5).
3. The app is built and tested.
4. The Docker image is pushed to ECR.
5. The app is deployed to EKS in the `webapp` namespace.
6. Jenkins checks whether the monitoring CRDs already exist.
7. If the monitoring stack is missing, Jenkins installs `kube-prometheus-stack` with Helm.
8. Jenkins applies the ServiceMonitor, PrometheusRule, and Grafana dashboard.
9. Jenkins validates that monitoring resources are ready.
10. Prometheus scrapes app metrics and Grafana shows the dashboards.
11. Alerts notify owners if deployment or monitoring checks fail.

## 5. Prerequisites

Before running the monitoring setup, ensure:

- AWS credentials are configured in Jenkins
- the EKS cluster already exists
- `kubectl` can access the cluster
- `helm` is available on the Jenkins agent, or can be downloaded by the pipeline
- the app image can be built and pushed to ECR
- the `monitoring` namespace is allowed in the cluster

## 6. Installation Commands

### 6.1 Local App Validation

From the repo root:

```bash
cd app
npm install
npm test
node server.js
```

Check metrics locally:

```bash
curl http://localhost:3000/
curl http://localhost:3000/healthz
curl http://localhost:3000/metrics
```

### 6.2 Build and Push the App Image

```bash
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=495013583028
export ECR_REPO_NAME=web-app-sprint4
export IMAGE_TAG=demo-1

docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} -f app/Dockerfile app
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
```

### 6.3 Deploy the Application Manually

```bash
aws eks update-kubeconfig --region ap-south-1 --name java-spring-eks

kubectl create namespace webapp --dry-run=client -o yaml | kubectl apply -f -
sed 's|REPLACE_IMAGE|495013583028.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint4:demo-1|g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl rollout status deployment/webapp -n webapp --timeout=300s
```

### 6.4 Install Prometheus and Grafana with Helm

If you want to install monitoring outside Jenkins, run:

```bash
export AWS_REGION=ap-south-1
export EKS_CLUSTER_NAME=java-spring-eks
export MONITORING_NAMESPACE=monitoring
export HELM_RELEASE_NAME=prometheus
export GRAFANA_ADMIN_PASSWORD=dev-grafana-admin

aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install ${HELM_RELEASE_NAME} prometheus-community/kube-prometheus-stack \
  --namespace ${MONITORING_NAMESPACE} \
  --create-namespace \
  --set grafana.adminPassword=${GRAFANA_ADMIN_PASSWORD} \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=1Gi
```

### 6.5 Apply Monitoring Manifests

```bash
kubectl apply -f monitoring/service-monitor-webapp.yaml
kubectl apply -f monitoring/prometheus-rules-webapp.yaml
kubectl apply -f monitoring/grafana-dashboard-webapp.yaml
```

### 6.6 Verify Monitoring Stack

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get servicemonitor -n monitoring
kubectl get prometheusrule -n monitoring
kubectl get configmap -n monitoring | grep grafana
```

## 7. Access Grafana

### Port-forward

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

### Open in Browser

- URL: `http://localhost:3000`
- Username: `admin`
- Password: the value used during bootstrap, for example `dev-grafana-admin`

## 8. Verify Prometheus Scraping

### Check the app endpoint

```bash
kubectl get svc -n webapp
kubectl get pods -n webapp
```

### Confirm the ServiceMonitor exists

```bash
kubectl get servicemonitor webapp-servicemonitor -n monitoring -o yaml
```

### Confirm the alert rules exist

```bash
kubectl get prometheusrule webapp-alert-rules -n monitoring -o yaml
```

### Confirm Prometheus target discovery

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Then open:

- `http://localhost:9090/targets`
- `http://localhost:9090/rules`

## 9. Jenkins Validation Flow

The pipeline in [Jenkinsfile.sprint5](../Jenkinsfile.sprint5) performs these monitoring checks:

1. ensures the app is healthy after deployment
2. ensures the `monitoring` namespace exists
3. bootstraps `kube-prometheus-stack` if CRDs are missing
4. applies monitoring manifests
5. waits for Prometheus/Grafana readiness
6. checks node readiness

If you want to trigger it manually, use the Jenkins job built from this file and set:

- `ENABLE_MONITORING_CHECKS=true`
- `RUN_DEPLOYMENT=true`
- optional `ALERT_WEBHOOK_URL` if you want outbound notifications

## 10. Useful Operational Commands

### App Health

```bash
curl http://<app-lb-or-ingress>/
curl http://<app-lb-or-ingress>/healthz
curl http://<app-lb-or-ingress>/metrics
```

### Kubernetes Diagnostics

```bash
kubectl get all -n webapp
kubectl describe deployment webapp -n webapp
kubectl logs -n webapp deployment/webapp --tail=200
kubectl get events -n webapp --sort-by=.metadata.creationTimestamp
```

### Monitoring Diagnostics

```bash
kubectl get all -n monitoring
kubectl describe pod -n monitoring -l app.kubernetes.io/name=prometheus
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
kubectl logs -n monitoring deploy/prometheus-grafana --tail=200
```

### Jenkins Diagnostics

If the pipeline fails, check:

```bash
kubectl logs -n jenkins deployment/jenkins --tail=200
```

and review the Jenkins Console Output for:

- AWS credential issues
- missing Helm or kubectl
- missing Prometheus CRDs
- failed rollout in the `webapp` namespace

## 11. Common Problems and Fixes

### Problem: Prometheus CRDs do not exist

Fix:
- run the Helm install command for `kube-prometheus-stack`
- rerun the Jenkins pipeline with `ENABLE_MONITORING_CHECKS=true`

### Problem: Grafana opens but dashboard is empty

Fix:
- check that [app/server.js](../app/server.js) exposes `/metrics`
- confirm the ServiceMonitor selects the `webapp` service
- confirm Prometheus is scraping the target

### Problem: Jenkins monitoring stage fails on Helm install

Fix:
- verify the Jenkins agent can download Helm
- verify EKS cluster access
- verify the `monitoring` namespace is permitted

### Problem: Alerts never fire

Fix:
- confirm PrometheusRule is installed
- confirm the alert expression matches live metrics
- generate a controlled failure or increase load to trigger thresholds

## 12. Recommended Setup Order

Use this order for a clean setup:

1. provision AWS infrastructure with Terraform
2. configure the management host with Ansible
3. deploy the app with `Jenkinsfile.sprint5`
4. install Prometheus and Grafana in the `monitoring` namespace
5. verify dashboards and alerts

## 13. Short Summary

If you only need the shortest path:

1. deploy app to EKS
2. install `kube-prometheus-stack`
3. apply `ServiceMonitor`, `PrometheusRule`, and Grafana dashboard
4. port-forward Grafana and confirm the dashboard
5. check Prometheus targets and alerts
