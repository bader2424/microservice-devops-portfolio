variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "bader-gitops-otel-demo"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["m7i-flex.large"]

  validation {
    condition     = alltrue([for instance_type in var.node_instance_types : can(regex("^[a-z][0-9][a-z]?[a-z0-9-]*\\.[a-z0-9]+$", instance_type))])
    error_message = "Each EKS node instance type must include a family and size, for example m7i-flex.large."
  }
}

variable "min_size" {
  type    = number
  default = 1
}

variable "desired_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}
