variable "environment" {
  description = "Environment"
  type        = string
}

variable "ecs_image" {
  description = "ECS Image"
  type        = string
}

variable "filebeat_image" {
  description = "ECS Image"
  type        = string
}

variable "cluster_ecs" {
  description = "The ECS cluster ID"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "CIDR for Private Subnets"
  type        = list(string)
}

variable "hostedzone_private" {
  description = "Hosted Zone Private"
  type        = string
}
