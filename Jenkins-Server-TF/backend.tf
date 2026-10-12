terraform {
  backend "s3" {
    bucket       = "dev-shahboz-tf-state-bucket"
    region       = "eu-north-1"
    key          = "End-to-End-Kubernetes-DevSecOps-Tetris-Project/Jenkins-Server-TF/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
  required_version = ">=1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.23.0"
    }
  }
}