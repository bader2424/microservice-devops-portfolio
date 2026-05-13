# CI/CD, DevSecOps, and Autoscaling

This project uses GitHub Actions and Argo CD together:

- Pull requests run Go tests, Docker build validation, Kubernetes schema validation, Trivy scans, Gitleaks secret scanning, and conditional Terraform validation when `infra/terraform` exists.
- Product Catalog changes build a container image, scan it with Trivy, push it to GitHub Container Registry, and update the GitOps Kubernetes deployment manifest.
- Argo CD syncs Kubernetes manifests into EKS.
- HPA scales selected services based on CPU metrics from Metrics Server.
- Cluster Autoscaler uses IRSA and EKS managed node group ASG tags to add/remove nodes when pods cannot schedule.

## Required GitHub Repository Settings

Enable GitHub Actions and make sure the default `GITHUB_TOKEN` has write access:

`Settings -> Actions -> General -> Workflow permissions -> Read and write permissions`

The CD workflow publishes to GHCR with `GITHUB_TOKEN`, so no Docker Hub secrets are required.

## Autoscaling Notes

The current demo profile is intentionally conservative for a one-node cost-controlled EKS environment. HPA max replicas are set to `2`, and the EKS managed node group should have `min=1`, `desired=1`, `max=2` so Cluster Autoscaler can add one node only when pending pods need it.

Do not run aggressive load tests for a long time while using AWS credits. Generate short bursts, capture screenshots, then scale back down.