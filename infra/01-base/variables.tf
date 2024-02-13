variable "environment" {
  description = "Environment 3 letters identifier"
  type        = string
}

variable "public_subnets_cidrs" {
  type = list(string)
}

variable "private_subnets_cidrs" {
  type = list(string)
}

variable "vpc_cidr_block" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "evaluation_period" {
  type        = string
  default     = "5"
  description = "The evaluation period over which to use when triggering alarms."
}

variable "statistic_period" {
  type        = string
  default     = "60"
  description = "The number of seconds that make each statistic period."
}

variable "alarm_slack_notification" {
  description = "Slack notifications SNS Arn"
  type        = map(string)
  default = {
    dev = "arn:aws:sns:us-east-1:703684915761:cloudwatch-to-slack"
    stg = "arn:aws:sns:us-east-1:703684915761:cloudwatch-to-slack"
    prd = "arn:aws:sns:us-east-1:703684915761:cloudwatch-to-slack"
  }
}