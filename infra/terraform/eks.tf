module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = var.cluster_version

  endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      name = "bader-${var.environment}-nodes"

      instance_types = var.node_instance_types

      min_size     = var.min_size
      desired_size = var.desired_size
      max_size     = var.max_size
    }
  }

  tags = local.tags
}
