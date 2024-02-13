variable "environment" {
  description = "Environment"
  type        = string
}

variable "ecs_image" {
  description = "ECS Image"
  type        = string
  default     = "685496751393.dkr.ecr.us-east-1.amazonaws.com/desafio:latest"
}