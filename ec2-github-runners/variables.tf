# This file is responsible to create variables

variable "number_of_machines" {
    description = "The number of instance ec2 that the terraform is going to create"
    type = number
    default = 5
}

variable "ec2_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "github_token" {
  description = "GitHub Runner Registration Token - Set via TF_VAR_github_token environment variable"
  type        = string
  sensitive   = true
}