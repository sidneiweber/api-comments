provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

terraform {
  backend "s3" {
    bucket = "terraform.BUCKETENVIRONMENT.desafio"
    key    = "services"
    region = "us-east-1"
  }
}

module "api-comments" {
  source      = "../modules/ecs-service"
  environment = var.environment
  name        = "api-comments"
  port        = 8000
}