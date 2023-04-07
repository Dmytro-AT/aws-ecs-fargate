terraform {
  backend "s3" {
    profile = "project"
    bucket  = "project-terraform-state"
    key     = "development/ecr/terraform.tfstate"
    region  = "eu-central-1"
  }
}

provider "aws" {
  profile = "project"
  region  = "eu-central-1"
}
