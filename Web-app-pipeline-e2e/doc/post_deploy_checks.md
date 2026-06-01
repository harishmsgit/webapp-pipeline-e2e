# Post-deploy Verification Checklist

Purpose
- Provide a clear, repeatable checklist to verify the cluster and application are running correctly after deployment.

Prerequisites
- `kubectl` is installed and configured to talk to the target cluster (kubeconfig or IAM auth).
- You can access the cluster from your workstation or Jenkins agent.

Variables to set (examples)
```bash
# Replace these with your actual names/values before running the quick scripts below
NAMESPACE=default
APP_LABEL=my-app
DEPLOYMENT=my-app-deployment
SERVICE=my-app-service
INGRESS_NAME=webapp-ingress
SERVICE_PORT=80        # port the Service listens on
INGRESS_HOST=app.example.com
```

Quick summary (run in order)
1. Verify cluster control plane
2. Confirm worker nodes are Ready
3. Confirm `kube-system` pods are healthy
4. Validate application Deployment and Pods
5. Verify Service / Ingress and external access
6. Smoke-test the application endpoint
7. Inspect application logs for errors
8. Check autoscaling / replica counts (if applicable)
9. Review events and system metrics
10. Document results and cleanup

Detailed checks

1) Verify cluster control plane
- Command:

```bash
kubectl get componentstatuses
# or (modern clusters):
kubectl get --raw='/healthz'
```
- Expected: components report healthy or `/healthz` returns OK.

2) Check worker nodes
- Command:

```bash
kubectl get nodes -o wide
```

- Expected: all nodes show `STATUS` = `Ready`. Note `AGE`, `VERSION`, and `INTERNAL-IP`.
- If nodes are NotReady, inspect `kubectl describe node <node>` and `kubectl get events --all-namespaces`.

3) Confirm system pods (`kube-system`)
- Command:

```bash
kubectl get pods -n kube-system
```

- Expected: `coredns`, `kube-proxy`, and other infra pods are `Running` or `Completed` (for jobs).
- Troubleshoot: `kubectl logs <pod> -n kube-system` or `kubectl describe pod <pod> -n kube-system`.

4) Check application Deployment and Pods
- Commands:

```bash
kubectl get deployments -n <app-namespace>
kubectl describe deployment <deployment-name> -n <app-namespace>
kubectl get pods -l app=<your-app-label> -n <app-namespace> -o wide
```

- Expected: `DESIRED` equals `UP-TO-DATE` and `AVAILABLE` replicas. Pods should be `Running`.
- If pods are CrashLoopBackOff, check `kubectl logs` and `kubectl describe pod` for reason.

5) Verify Service / Ingress and external IP
- Commands:

```bash
kubectl get svc -n <app-namespace>
kubectl describe svc <service-name> -n <app-namespace>
# If using ingress:
kubectl get ingress -n <app-namespace>
kubectl describe ingress <ingress-name> -n <app-namespace>
```

- Expected:
  - `LoadBalancer` Services eventually show an `EXTERNAL-IP` (it can take a minute).
  - `NodePort` and `ClusterIP` services are reachable via node IP + port or port-forward.

6) Smoke test the application endpoint
- For `LoadBalancer`:

```bash
curl -v http://<EXTERNAL-IP>/
```

- For `NodePort` (replace `<NODE-IP>` and `<NODEPORT>`):

```bash
curl -v http://<NODE-IP>:<NODEPORT>/
```

- For `ClusterIP` (local test via port-forward):

```bash
kubectl port-forward svc/<service-name> 8080:80 -n <app-namespace>
curl http://localhost:8080/health
```

- Expected: HTTP 200 or application-specific healthy response.

7) Inspect application logs
- Command:

```bash
kubectl logs <pod-name> -n <app-namespace> --follow
```

- Look for stack traces, error messages, failed DB connections, or repeated restarts.

8) Check autoscaling / replica counts (if HPA used)
- Commands:

```bash
kubectl get hpa -n <app-namespace>
kubectl describe hpa <hpa-name> -n <app-namespace>
```

- Expected: HPA metrics are available and replicas scale to match thresholds.

9) Review events and system metrics
- Commands:

```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
# If monitoring (Prometheus/Grafana) is installed, verify target metrics
```

- Look for recent `Warning` or `Failed` events tied to the app or nodes.

10) Document results & cleanup
- Record:
  - Cluster name / context
  - Node list and statuses
  - Deployment name and replica counts
  - Service type and external IPs
  - Any errors found and remediation steps taken

Example quick-run script (manual use)

```bash
# set namespace and names
NAMESPACE=default
DEPLOY=my-app-deployment
SVC=my-app-service

kubectl config current-context
kubectl get nodes -o wide
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE

# get one pod of the deployment
POD=$(kubectl get pods -n $NAMESPACE -l app=my-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -n $NAMESPACE --tail=200
```

Troubleshooting tips
- Pod stuck in `Pending`: usually insufficient cluster capacity or scheduling failure; run `kubectl describe pod` to see reasons (insufficient CPU/memory, taints). If capacity is the issue, consider scaling node group or using smaller instance types.
- LoadBalancer never gets `EXTERNAL-IP`: ensure cloud provider supports LB and has permissions; check `kubectl describe svc` and cloud console for pending LB.
- DNS issues: verify DNS (external) records point to the LoadBalancer and TTLs.

Automation note
- Add CI steps to run the smoke-test `curl` after `terraform apply` / Helm deploy; fail the pipeline on non-200 responses.

Recording results
- Save a short report to the repo `doc/deploy_reports/<timestamp>_post_deploy.md` with the values collected above.

If you want, I can:
- Add a small script under `scripts/` that runs these checks and outputs a simple report.
- Run the checks interactively if you paste `kubectl` outputs or kubeconfig.

---

Generated by the automation checklist for this project.