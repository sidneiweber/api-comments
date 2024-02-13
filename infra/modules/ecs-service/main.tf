data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "base"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "traefik" {
  backend = "s3"

  config = {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "traefik"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

data "external" "task_definition" {
  program = ["bash", "${path.module}/../ecs-task-definition.sh"]
  query = {
    service   = var.name
    cluster   = var.environment
    path_root = jsonencode(path.root)
  }
}

locals {
  should_scale_by_cpu    = var.auto_scaling_type == "step" && var.auto_scaling_metric == "cpu" ? true : false
  should_scale_by_memory = var.auto_scaling_type == "step" && var.auto_scaling_metric == "memory" ? true : false
  default_tags = {
    Service = var.name
  }
  default_envs = [
    {
      name : "AWS_REGION",
      value : "us-east-1"
    },
  ]
  merged_env_vars = concat(
    lookup(var.env_vars, var.environment, []),
    lookup(var.env_vars, "all", []),
    local.default_envs
  )
  env_vars = join(",", [
    for env_var in local.merged_env_vars :
    jsonencode(env_var)
  ])
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.environment == "prd" ? "60" : "14"
}

resource "aws_ecr_repository" "ecr_repository" {
  name = var.name
}

resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr_repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep base image",
            "selection": {
                "countType": "imageCountMoreThan",
                "countNumber": 1,
                "tagStatus": "tagged",
                "tagPrefixList": [
                    "base-image"
                ]
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Keep last ${var.environment != "prd" ? 10 : 20} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.environment != "prd" ? 10 : 20}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecs_service" "service" {
  name                               = var.name
  cluster                            = var.environment
  task_definition                    = "${aws_ecs_task_definition.task_definition.family}:${data.external.task_definition.result["task_definition_revision"] > aws_ecs_task_definition.task_definition.revision ? data.external.task_definition.result["task_definition_revision"] : aws_ecs_task_definition.task_definition.revision}"
  launch_type                        = var.environment != "prd" || var.use_spot == true ? null : "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  propagate_tags                     = "TASK_DEFINITION"
  enable_execute_command             = true

  depends_on = [aws_ecs_task_definition.task_definition, data.external.task_definition]

  dynamic "capacity_provider_strategy" {
    for_each = var.environment != "prd" ? ["spot_provider_strategy"] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.environment == "prd" && var.use_spot == true ? ["prd_spot_provider_strategy"] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 2
      base              = 0
    }
  }
  dynamic "capacity_provider_strategy" {
    for_each = var.environment == "prd" && var.use_spot == true ? ["prd_ondemand_provider_strategy"] : []
    content {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = var.ondemand_base
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_security_group.id]
    subnets          = data.terraform_remote_state.base.outputs.private_subnets
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.name}.service.${var.environment}.desafio"
    },
  )
}

resource "aws_iam_role" "task_role" {
  count = var.extra_policies != null ? 1 : 0
  name  = "${var.name}-${var.environment}-iam-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.default_tags,
    {
      Name = "${var.name}.role.${var.environment}.desafio"
    },
  )
}

resource "aws_iam_role_policy" "task_role_policy" {
  for_each = var.extra_policies != null ? local.policies : {}
  name     = each.key
  role     = aws_iam_role.task_role[0].id
  policy   = each.value
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.name
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = var.extra_policies != null ? aws_iam_role.task_role[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory

  tags = merge(
    local.default_tags,
    {
      Name = "${var.name}.task.${var.environment}.desafio"
    },
  )

  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${data.external.task_definition.result["full_image"]}",
    "essential": true,
    "cpu": 0,
    "mountPoints": [],
    "volumesFrom": [],
    "dockerLabels": {
      "traefik.enable": "true",
      %{if var.health_check_path != "/"}
      "traefik.http.services.${var.name}.loadbalancer.healthcheck.path": "${var.health_check_path}",
      "traefik.http.services.${var.name}.loadbalancer.healthcheck.interval": "${var.health_check_interval}",
      "traefik.http.services.${var.name}.loadbalancer.healthcheck.timeout": "${var.health_check_timeout}",
      "traefik.http.services.${var.name}.loadbalancer.healthcheck.port": "${var.port}",
      %{endif~}
      %{if var.metrics_port != null}
      "PROMETHEUS_EXPORTER_PATH": "${var.metrics_path != "" ? var.metrics_path : "/metrics"}",
      "PROMETHEUS_EXPORTER_PORT": "${var.metrics_port}",
      %{endif~}
      "traefik.http.services.${var.name}.loadbalancer.server.scheme": "${var.loadbalancer_protocol}",
      "traefik.http.services.${var.name}.loadbalancer.server.port": "${var.port}",
      "traefik.http.routers.${var.name}.middlewares":"${var.name}-ratelimit@ecs",
      "traefik.http.middlewares.${var.name}-ratelimit.ratelimit.average":"${var.ratelimit_average}",
      "traefik.http.middlewares.${var.name}-ratelimit.ratelimit.period":"${var.ratelimit_period}",
      "traefik.http.middlewares.${var.name}-ratelimit.ratelimit.burst":"${var.ratelimit_burst}",
      "traefik.http.middlewares.${var.name}-ratelimit.ratelimit.sourcecriterion.ipstrategy.depth":"${var.ratelimit_ip_depth}",
      "traefik.http.routers.${var.name}.rule": "Host(`${var.name}.sidneiweber.com.br`)"
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "${var.environment}"
      }
    },
    "portMappings": [
      {
        "hostPort": ${var.port},
        "protocol": "tcp",
        "containerPort": ${var.port}
      }
    ],
    "command": [${join(",", formatlist("\"%s\"", var.command))}],
    "entrypoint": [${join(",", formatlist("\"%s\"", var.entrypoint))}],
    "stopTimeout": ${var.stop_timeout}
  }
]
  EOF
}

resource "aws_security_group" "ecs_security_group" {
  name        = "${var.environment}-${var.name}-sg"
  description = "${var.environment} ${var.name} ECS SERVICE SECURITY GROUP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    description     = "From Traefik"
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.traefik.outputs.traefik_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.default_tags,
    {
      Name = "${var.name}.securitygroup.${var.environment}.desafio"
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  count               = var.environment == "prd" ? 1 : 0
  alarm_name          = "${var.name}CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.cpu_alarm_period
  statistic           = "Maximum"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "Maximum CPU utilization higher than ${var.alarm_cpu_threshold} %"
  treat_missing_data  = var.auto_scaling_min_capacity == 0 ? "ignore" : null
  alarm_actions       = local.should_scale_by_cpu ? [aws_appautoscaling_policy.scale_up_step_policy[count.index].arn] : []
  ok_actions          = local.should_scale_by_cpu ? [aws_appautoscaling_policy.scale_down_step_policy[count.index].arn] : []
  dimensions = {
    ClusterName = var.environment
    ServiceName = aws_ecs_service.service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  count               = var.environment == "prd" ? 1 : 0
  alarm_name          = "${var.name}MemoryUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.alarm_memory_threshold
  alarm_description   = "Maximum Memory utilization higher than ${var.alarm_memory_threshold}%"
  treat_missing_data  = var.auto_scaling_min_capacity == 0 ? "ignore" : null
  alarm_actions       = local.should_scale_by_memory ? [aws_appautoscaling_policy.scale_up_step_policy[count.index].arn] : []
  ok_actions          = local.should_scale_by_memory ? [aws_appautoscaling_policy.scale_down_step_policy[count.index].arn] : []
  dimensions = {
    ClusterName = var.environment
    ServiceName = aws_ecs_service.service.name
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.auto_scaling_type != "none" ? 1 : 0
  min_capacity       = var.auto_scaling_min_capacity
  max_capacity       = var.auto_scaling_max_capacity
  resource_id        = "service/${var.environment}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "autoscaling_target_policy" {
  depends_on         = [aws_appautoscaling_target.ecs_target]
  count              = var.auto_scaling_type == "target" ? 1 : 0
  name               = "${var.auto_scaling_metric == "cpu" ? "ECSServiceAverageCPUUtilization" : "ECSServiceAverageMemoryUtilization"}:${var.name}"
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.auto_scaling_metric == "cpu" ? "ECSServiceAverageCPUUtilization" : "ECSServiceAverageMemoryUtilization"
    }

    target_value       = var.auto_scaling_target_value
    scale_out_cooldown = var.auto_scaling_up_cooldown
    scale_in_cooldown  = var.auto_scaling_down_cooldown
  }
}

resource "aws_appautoscaling_policy" "scale_up_step_policy" {
  depends_on         = [aws_appautoscaling_target.ecs_target]
  count              = var.auto_scaling_type == "step" ? 1 : 0
  name               = "${var.name}-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.auto_scaling_up_cooldown
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 1
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_step_policy" {
  depends_on         = [aws_appautoscaling_target.ecs_target]
  count              = var.auto_scaling_type == "step" ? 1 : 0
  name               = "${var.name}-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.auto_scaling_down_cooldown
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

