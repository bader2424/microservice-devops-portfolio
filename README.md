# Microservice DevOps Portfolio

Production-style DevOps portfolio based on the OpenTelemetry Astronomy Shop demo.

This repository started as a fork of the open-source `opentelemetry-demo`, then I extended it into an end-to-end cloud DevOps project. The application is a realistic microservice e-commerce system, and the project demonstrates how to run it locally with Docker and deploy it to AWS using Terraform, EKS, Kubernetes, Argo CD, CI/CD, DevSecOps, and observability tooling.

> Note: the full DevOps implementation is on the `gitops-bader-clean` branch. If you are viewing the `main` branch before that branch is merged, check out `gitops-bader-clean` to see the Terraform, GitOps, CI/CD, autoscaling, and observability files.

## What I Built

- Deployed the full microservice application to AWS EKS.
- Created AWS infrastructure with Terraform, including VPC, subnets, NAT gateway, EKS, managed node group, IAM integration, and ECR repositories.
- Used Kubernetes Deployments, Services, Ingress, ServiceAccounts, and HPAs.
- Exposed the application publicly through an AWS Application Load Balancer.
- Implemented GitOps deployment with Argo CD using an app-of-apps structure.
- Added GitHub Actions CI/CD for testing, image build, image scan, GHCR push, and manifest update.
- Added DevSecOps checks with Trivy, Checkov, Gitleaks, and Kubernetes manifest validation.
- Added observability with Prometheus, Grafana, Loki, Jaeger, OpenTelemetry Collector, and AWS CloudWatch.
- Added Kubernetes HPA and Cluster Autoscaler manifests for scaling.
- Added cost-control and cleanup practices for an AWS credits/free-tier style environment.

## Architecture

```text
Developer
  -> GitHub
  -> GitHub Actions CI/CD
  -> GitHub Container Registry
  -> GitOps manifest update
  -> Argo CD
  -> AWS EKS
  -> Kubernetes Deployments / Services / Ingress
  -> AWS Application Load Balancer
  -> OpenTelemetry Demo application
```

Runtime traffic:

```text
User -> AWS ALB -> Kubernetes Ingress -> frontend-proxy Service -> frontend Pod -> backend microservices
```

Observability:

```text
Application Pods -> OpenTelemetry Collector -> Jaeger
Kubernetes Metrics -> Prometheus -> Grafana
Pod Logs -> Promtail -> Loki -> Grafana
Cluster Logs/Metrics -> AWS CloudWatch
```

## Tech Stack

| Area | Tools |
|---|---|
| Application | OpenTelemetry Astronomy Shop microservices |
| Containers | Docker, Docker Compose |
| Cloud | AWS, EKS, EC2, VPC, ALB, IAM, ECR, CloudWatch |
| Infrastructure as Code | Terraform |
| Kubernetes | Deployments, Services, Ingress, HPA, ServiceAccounts |
| GitOps | Argo CD app-of-apps |
| CI/CD | GitHub Actions, GHCR |
| Security | Trivy, Checkov, Gitleaks, kubeconform |
| Observability | Prometheus, Grafana, Loki, Jaeger, OpenTelemetry Collector |
| Scaling | Kubernetes HPA, Cluster Autoscaler |

## Repository Structure

```text
.github/workflows/      GitHub Actions CI/CD and DevSecOps pipelines
infra/terraform/        AWS infrastructure as code
gitops/                 Argo CD app-of-apps and platform apps
kubernetes/             Kubernetes manifests for the microservices
src/                    Microservice source code and Dockerfiles
scripts/                Local and AWS helper scripts
docs/                   Project documentation and study guide
docker-compose.yml      Local full-stack deployment
```

## Run Locally with Docker

Requirements:

- Docker
- Docker Compose

Start the application:

```bash
git clone https://github.com/bader2424/microservice-devops-portfolio.git
cd microservice-devops-portfolio
git checkout gitops-bader-clean
docker compose up --force-recreate --remove-orphans --detach
```

Or use the helper script:

```bash
./scripts/local-up.sh
```

Open:

```text
Application: http://localhost:8080
Grafana:     http://localhost:8080/grafana
Jaeger:      http://localhost:8080/jaeger/ui
```

Stop locally:

```bash
docker compose down --remove-orphans
```

## Deploy to AWS EKS with Terraform and Argo CD

Requirements:

- AWS CLI configured
- Terraform
- kubectl
- Helm
- Argo CD CLI optional

Verify AWS access:

```bash
aws sts get-caller-identity
```

Create infrastructure:

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

Connect kubectl to EKS:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name bader-gitops-otel-demo-dev

kubectl get nodes
```

Install Argo CD:

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

Deploy the GitOps root app:

```bash
kubectl apply -f gitops/root-app.yaml
kubectl get applications -n argocd
```

Check the application:

```bash
kubectl get pods -n otel-demo
kubectl get svc -n otel-demo
kubectl get ingress -n otel-demo
```

Open the public ALB address from:

```bash
kubectl get ingress -n otel-demo
```

## CI/CD and DevSecOps

The repository includes two main GitHub Actions workflows:

- `devsecops-ci`: runs Go checks, Docker build validation, Kubernetes manifest validation, Trivy scans, Gitleaks, Terraform validation, and Checkov.
- `product-catalog-cd`: builds the Product Catalog image, scans it, pushes it to GHCR, updates the Kubernetes deployment image tag, and lets Argo CD deploy it.

Delivery flow:

```text
Code change -> GitHub Actions -> Docker image -> Security scan -> GHCR -> Manifest update -> Argo CD sync -> EKS rollout
```

## Observability

The project includes:

- Prometheus for metrics.
- Grafana for dashboards.
- Loki and Promtail for logs.
- Jaeger for distributed tracing.
- OpenTelemetry Collector for telemetry routing.
- AWS CloudWatch for AWS-native cluster logs and metrics.

Useful checks:

```bash
kubectl get pods -n observability
kubectl port-forward svc/grafana -n observability 3000:80
kubectl port-forward svc/prometheus-server -n observability 9090:80
kubectl port-forward svc/jaeger-query -n observability 16686:16686
```

## Cleanup

AWS resources can cost money. Destroy the infrastructure when the demo is finished:

```bash
cd infra/terraform
terraform destroy
```

Also confirm that load balancers, EBS volumes, NAT gateways, and CloudWatch log retention are cleaned up.

## Project Status

This is a portfolio project designed to demonstrate real DevOps skills:

- Cloud infrastructure provisioning
- Kubernetes deployment
- GitOps delivery
- CI/CD automation
- DevSecOps scanning
- Observability
- Autoscaling
- Troubleshooting
- AWS cost awareness

The application source is based on the OpenTelemetry Astronomy Shop demo. The DevOps platform, AWS deployment, GitOps structure, CI/CD, security scanning, and observability work were added as part of this portfolio.
