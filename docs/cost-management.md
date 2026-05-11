# AWS and Kubernetes Cost Management

This project includes a lightweight cost-control story that fits the EKS demo environment without adding another heavy in-cluster platform.

## AWS Cost Explorer

Use AWS Cost Explorer for service-level spend and tag-based reporting.

Recommended project tags already used by the infrastructure:

- `Owner=bader`
- `Project=bader-gitops-otel-demo`
- `Environment=dev`
- `ManagedBy=Terraform`

Cost Explorer and Cost Allocation Tags are not instant. After enabling them in AWS Billing, AWS can take several hours, sometimes up to 24 hours, before tag-based cost data appears.

### Enable Cost Explorer

AWS Console:

`Billing and Cost Management -> Cost Explorer -> Launch Cost Explorer`

### Activate Cost Allocation Tags

AWS Console:

`Billing and Cost Management -> Cost Allocation Tags -> User-defined cost allocation tags`

Activate at least:

- `Project`
- `Owner`
- `Environment`
- `ManagedBy`

Then run:

```bash
AWS_REGION=us-east-1 DAYS=14 ./scripts/aws-cost-report.sh
```

Useful screenshots:

- Cost Explorer daily cost grouped by service
- Cost Explorer filtered by `Project=bader-gitops-otel-demo`
- Activated cost allocation tags
- Terminal output from `scripts/aws-cost-report.sh`

## Kubernetes Cost Allocation

For this single-node/free-credit demo, the project uses lightweight namespace allocation based on Kubernetes resource requests and live usage from Metrics Server.

Run:

```bash
./scripts/k8s-cost-allocation-report.sh
```

Optional rough node-cost estimate:

```bash
INSTANCE_HOURLY_COST=0.10 ./scripts/k8s-cost-allocation-report.sh
```

Useful screenshots:

- `kubectl top nodes`
- `kubectl top pods -A`
- Namespace request allocation table
- HPA output showing CPU-based scaling

## Why Not Deploy Kubecost/OpenCost By Default?

Kubecost/OpenCost is useful, but it adds more in-cluster pods and resource pressure. This project already runs Argo CD, Prometheus, Grafana, Loki, Jaeger, CloudWatch, Metrics Server, and Cluster Autoscaler on a very small EKS setup. For cost control, the default portfolio profile keeps cost reporting script-based and AWS-native.

If the cluster is recreated with more capacity, OpenCost can be added later as a GitOps application backed by the existing Prometheus instance.

## Cleanup Reminder

When screenshots are complete, reduce cost:

```bash
kubectl scale deployment cluster-autoscaler -n kube-system --replicas=0
aws eks update-nodegroup-config \
  --cluster-name bader-gitops-otel-demo-dev \
  --nodegroup-name bader-dev-nodes-20260511053700083200000002 \
  --region us-east-1 \
  --scaling-config minSize=1,maxSize=2,desiredSize=1
```

For full cleanup:

```bash
cd /home/bader/projects/microservice-devops-project/infra/terraform
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
```