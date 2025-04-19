terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }
  }

  backend "s3" {
    bucket         = "remote-state-tf1-dev"
    key            = "expense-eks-bastion"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
  }
}
provider "aws" {
  # Configuration options
  region = "us-east-1"
}