aws_region      = "us-east-1"
project_name    = "bader-gitops-otel-demo"
environment     = "dev"
cluster_version = "1.31"

node_instance_types = ["m7i-flex.large"]
min_size            = 1
desired_size        = 1
max_size            = 2
