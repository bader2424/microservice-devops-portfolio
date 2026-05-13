locals {
  ecr_repositories = [
    "frontend",
    "frontend-proxy",
    "cart",
    "checkout",
    "currency",
    "email",
    "payment",
    "product-catalog",
    "recommendation",
    "shipping",
    "ad",
    "load-generator"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.ecr_repositories)

  name                 = "${local.name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}
