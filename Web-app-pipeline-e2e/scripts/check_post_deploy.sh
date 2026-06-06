#!/usr/bin/env bash
# Post-deploy verification script
# Usage: NAMESPACE=default APP_LABEL=my-app SERVICE=my-app-service ./scripts/check_post_deploy.sh

set -uo pipefail

timestamp=$(date -u +"%Y%m%dT%H%M%SZ")
report_dir="doc/deploy_reports"
mkdir -p "$report_dir"
report_file="$report_dir/${timestamp}_post_deploy.md"

# Defaults (can be overridden via env)
NAMESPACE=${NAMESPACE:-default}
APP_LABEL=${APP_LABEL:-my-app}
DEPLOYMENT=${DEPLOYMENT:-my-app-deployment}
SERVICE=${SERVICE:-my-app-service}
INGRESS_NAME=${INGRESS_NAME:-webapp-ingress}
SERVICE_PORT=${SERVICE_PORT:-80}

echo "# Post-deploy verification report - $timestamp" > "$report_file"
echo "Context: $(kubectl config current-context 2>/dev/null || echo 'no-context')" >> "$report_file"
echo "Namespace: $NAMESPACE" >> "$report_file"

echo "== Cluster context and nodes ==" | tee -a "$report_file"
kubectl config current-context 2>&1 | tee -a "$report_file"

echo "\n== Nodes ==" | tee -a "$report_file"
kubectl get nodes -o wide 2>&1 | tee -a "$report_file"

echo "\n== kube-system pods ==" | tee -a "$report_file"
kubectl get pods -n kube-system 2>&1 | tee -a "$report_file"

echo "\n== Deployments in namespace $NAMESPACE ==" | tee -a "$report_file"
kubectl get deployments -n "$NAMESPACE" 2>&1 | tee -a "$report_file"

echo "\n== Pods (label: app=$APP_LABEL) in $NAMESPACE ==" | tee -a "$report_file"
kubectl get pods -l app="$APP_LABEL" -n "$NAMESPACE" -o wide 2>&1 | tee -a "$report_file"

# Service and ingress
echo "\n== Service $SERVICE in $NAMESPACE ==" | tee -a "$report_file"
kubectl get svc "$SERVICE" -n "$NAMESPACE" -o wide 2>&1 | tee -a "$report_file" || echo "Service $SERVICE not found" | tee -a "$report_file"

# Describe service
if kubectl get svc "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  kubectl describe svc "$SERVICE" -n "$NAMESPACE" 2>&1 | tee -a "$report_file"
fi

# Ingress
echo "\n== Ingress $INGRESS_NAME in $NAMESPACE ==" | tee -a "$report_file"
if kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o wide 2>&1 | tee -a "$report_file"
  kubectl describe ingress "$INGRESS_NAME" -n "$NAMESPACE" 2>&1 | tee -a "$report_file"
else
  echo "Ingress $INGRESS_NAME not found" | tee -a "$report_file"
fi

# Attempt to determine external endpoint
EXTERNAL=""
# prefer service LoadBalancer
if kubectl get svc "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null | grep -q .; then
  EXTERNAL=$(kubectl get svc "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
elif kubectl get svc "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null | grep -q .; then
  EXTERNAL=$(kubectl get svc "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

# fallback to ingress host
if [ -z "$EXTERNAL" ]; then
  if kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null | grep -q .; then
    EXTERNAL=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
  fi
fi

if [ -n "$EXTERNAL" ]; then
  echo "\n== External endpoint detected: $EXTERNAL ==" | tee -a "$report_file"
  echo "Curling http://$EXTERNAL:$SERVICE_PORT/ ..." | tee -a "$report_file"
  curl -sS -m 10 "http://$EXTERNAL:$SERVICE_PORT/" 2>&1 | tee -a "$report_file" || echo "curl failed" | tee -a "$report_file"
else
  echo "\nNo external endpoint detected for service/ingress. Consider port-forwarding or using NodePort." | tee -a "$report_file"
fi

# Get logs from one app pod
POD=$(kubectl get pods -l app="$APP_LABEL" -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$POD" ]; then
  echo "\n== Logs for pod $POD ==" | tee -a "$report_file"
  kubectl logs "$POD" -n "$NAMESPACE" --tail=200 2>&1 | tee -a "$report_file"
else
  echo "\nNo pod found with label app=$APP_LABEL in $NAMESPACE" | tee -a "$report_file"
fi

# Events
echo "\n== Recent events (sorted) ==" | tee -a "$report_file"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' 2>&1 | tail -n 200 | tee -a "$report_file"

cat "$report_file"

echo "\nReport saved to $report_file"

exit 0
