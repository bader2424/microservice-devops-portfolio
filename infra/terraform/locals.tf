locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = "bader"
    ManagedBy   = "Terraform"
    Purpose     = "DevOpsPortfolio"
  }
}
