variable "environment" {}

variable "name" {
  description = "Service name"
  type        = string
}

variable "cpu" {
  description = "CPU"
  type        = number
  default     = 256

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-taskdefinition.html#cfn-ecs-taskdefinition-cpu
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "Argument \"cpu\" must be either 256, 512, 1024, 2048 or 4096."
  }
}

variable "memory" {
  description = "Memory"
  type        = number
  default     = 512

  # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-taskdefinition.html#cfn-ecs-taskdefinition-cpu
  validation {
    condition     = contains(concat([512], range(1024, 30720, 1024)), var.memory)
    error_message = "Argument \"memory\" must be 512 or a multiple of 1024 between 1024 and 30720."
  }
}

variable "command" {
  description = "Command"
  type        = list(string)
  default     = []
}

variable "entrypoint" {
  description = "Entrypoint"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Service Port"
  type        = number
  default     = 8080
}

variable "public" {
  type    = bool
  default = true
}

variable "env_vars" {
  description = "Object Containing Env Vars per Environment"
  default     = {}
}

variable "health_check_path" {
  description = "Is appended to the server URL to set the health check endpoint"
  type        = string
  default     = "/health"

  validation {
    condition     = can(regex("^(\\/)", var.health_check_path))
    error_message = "ERROR: Invalid option, must start with a slash (/)."
  }
}

variable "health_check_interval" {
  description = "Defines the frequency of the health check calls"
  type        = number
  default     = 10
}

variable "health_check_timeout" {
  description = "Defines the maximum duration Traefik will wait for a health check request before considering the server failed (unhealthy)"
  type        = number
  default     = 5
}

variable "use_spot" {
  default = false
}

variable "ondemand_base" {
  description = "Number of base tasks on demand"
  type        = number
  default     = 1
}

variable "stop_timeout" {
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own."
  type        = number
  default     = 30
}

variable "auto_scaling_type" {
  description = "Enable Auto Scaling"
  type        = string
  default     = "none"

  validation {
    condition     = can(regex("^(none|step|target)$", var.auto_scaling_type))
    error_message = "ERROR: Invalid option, must be either none, step or target."
  }
}

variable "auto_scaling_metric" {
  description = "Auto Scaling Metric to use"
  type        = string
  default     = "cpu"

  validation {
    condition     = can(regex("^(cpu|memory)$", var.auto_scaling_metric))
    error_message = "ERROR: Invalid option, must be either cpu or memory."
  }
}

variable "auto_scaling_min_capacity" {
  description = "Auto Scaling Min Capacity"
  type        = number
  default     = 1
}

variable "auto_scaling_max_capacity" {
  description = "Auto Scaling Max Capacity"
  type        = number
  default     = 4
}

variable "auto_scaling_up_cooldown" {
  description = "Auto Scaling Up Cooldown"
  type        = number
  default     = 120
}

variable "auto_scaling_down_cooldown" {
  description = "Auto Scaling Down Cooldown"
  type        = number
  default     = 300
}

variable "alarm_cpu_threshold" {
  description = "The value against which the specified statistic is compared"
  type        = string
  default     = "80"

  validation {
    condition     = var.alarm_cpu_threshold > 0 && var.alarm_cpu_threshold < 100
    error_message = "ERROR: Invalid option, must be between 0 to 99."
  }
}

variable "alarm_memory_threshold" {
  description = "The value against which the specified statistic is compared"
  type        = string
  default     = "80"

  validation {
    condition     = var.alarm_memory_threshold > 0 && var.alarm_memory_threshold < 100
    error_message = "ERROR: Invalid option, must be between 0 to 99."
  }
}

variable "auto_scaling_target_value" {
  description = "Enable Auto Scaling"
  type        = number
  default     = 70
}

variable "extra_policies" {
  description = "Extra policies to add to the task role"
  type        = map(string)
  default     = null
}

variable "cpu_alarm_evaluation_periods" {
  description = "Evaluation periods for CPU Alarm"
  type        = string
  default     = "2"
}

variable "cpu_alarm_period" {
  description = "Evaluation periods for CPU Alarm"
  type        = string
  default     = "300"
}

variable "loadbalancer_protocol" {
  description = "Traefik loadBalancer protocol"
  type        = string
  default     = "http"

  validation {
    condition     = can(regex("^(http|h2c)$", var.loadbalancer_protocol))
    error_message = "ERROR: Invalid option, must be either http or h2c."
  }
}

variable "ratelimit_average" {
  description = "Maximum rate, by default in requests by second, allowed for the given source (0 to no rate limiting)"
  type        = number
  default     = 10
}

variable "ratelimit_period" {
  description = "In combination with ratelimit_average, defines the actual maximum rate (r = average / period)"
  type        = string
  default     = "5s"
}

variable "ratelimit_burst" {
  description = "Maximum number of requests allowed to go through in the same arbitrarily small period of time"
  type        = number
  default     = 20
}

variable "ratelimit_ip_depth" {
  description = "Use the X-Forwarded-For header and take the IP located at the depth position (starting from the right)"
  type        = number
  default     = 1
}

variable "metrics_port" {
  description = "Port that Prometheus will use to collect metrics"
  type        = number
  default     = null
}

variable "metrics_path" {
  description = "Path that Prometheus will use to collect metrics"
  type        = string
  default     = "/metrics"
}
