provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment
      Service     = "Traefik"
      Team        = "DevOps"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "terraform.BUCKETENVIRONMENT.warren.com.br"
    key    = "traefik2"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "cloudformation" {
  backend = "s3"

  config = {
    bucket = "terraform.BUCKETENVIRONMENT.warren.com.br"
    key    = "import-cloudformation"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "LogGroup" {
  name              = "/ecs/traefik2"
  retention_in_days = var.environment == "prd" ? "60" : "14"
}

resource "aws_iam_policy" "Policy" {
  name = "${var.environment}-traefik2"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:*",
        "ec2:DescribeInstances*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "TaskRole" {
  name = "${var.environment}-traefik2"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "IamEcsTaskExecutionRole" {
  name = "${var.environment}-Traefik2EcsTaskExecutionRole"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role       = aws_iam_role.IamEcsTaskExecutionRole.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "TraefikPolicy" {
  role       = aws_iam_role.TaskRole.id
  policy_arn = aws_iam_policy.Policy.id
}

resource "aws_iam_instance_profile" "IAMCloudwatchInstanceProfile" {
  name = "${var.environment}_ecs_instance_profile"
  role = aws_iam_role.IamEcsTaskExecutionRole.name
}

resource "aws_ecs_task_definition" "TaskDefinition" {
  family                   = "traefik2"
  execution_role_arn       = aws_iam_role.IamEcsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.TaskRole.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.environment == "prd" ? 512 : 256
  memory                   = var.environment == "prd" ? 1024 : 512
  volume {
    name = "accesslog"
  }

  container_definitions = <<EOF
[
  {
    "name": "traefik2",
    "image": "${var.ecs_image}",
    "mountPoints": [
      {
        "readOnly": false,
        "containerPath": "/tmp/traefik",
        "sourceVolume": "accesslog"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.LogGroup.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "${var.environment}"
      }
    },
    "portMappings": [
      {
        "hostPort": 443,
        "protocol": "tcp",
        "containerPort": 443
      },
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      },
      {
        "hostPort": 8080,
        "protocol": "tcp",
        "containerPort": 8080
      },
      {
        "hostPort": 8081,
        "protocol": "tcp",
        "containerPort": 8081
      },
      {
        "hostPort": 8082,
        "protocol": "tcp",
        "containerPort": 8082
      }
    ],
    "environment": [
      {
        "name": "AWS_REGION",
        "value": "us-east-1"
      },
      {
        "name": "CLUSTER_HOST",
        "value": "${var.cluster_ecs}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${var.environment}"
      }
    ],
    "ulimits": [
      {
        "name": "nofile",
        "softLimit": 10240,
        "hardLimit": 65536
      }
    ],
    "dockerLabels": {
      "traefik.http.services.traefik.loadbalancer.server.port": "8080",
      "traefik.http.routers.traefik.rule": "Host(`traefik2.${var.environment}.warren.com.br`)",
      "traefik.enable": "true",
      "traefik.http.services.traefik.loadbalancer.server.scheme": "http",
      "traefik.http.routers.traefik.middlewares": "traefik@ecs",
      "traefik.http.routers.traefik.service": "traefik@ecs",
      "traefik.http.middlewares.traefik.ratelimit.average": "0",
      "traefik.http.middlewares.traefik.ratelimit.burst": "20",
      "traefik.http.middlewares.traefik.ratelimit.period": "5s",
      "traefik.http.middlewares.traefik.ratelimit.sourcecriterion.ipstrategy.depth": "1",
      "traefik.http.services.traefik-prometheus.loadbalancer.server.port": "8082",
      "traefik.http.routers.traefik-prometheus.rule": "Host(`traefik-prometheus.${var.environment}.warren.com.br`)",
      "traefik.http.services.traefik-prometheus.loadbalancer.server.scheme": "http",
      "traefik.http.routers.traefik-prometheus.service": "traefik-prometheus@ecs",
      "PROMETHEUS_EXPORTER_PATH": "/metrics",
      "PROMETHEUS_EXPORTER_PORT": "8082"
    },
    "privileged": null
  },
  {
    "name": "traefik-filebeat",
    "image": "${var.filebeat_image}",
    "essential": false,
    "mountPoints": [
      {
        "readOnly": true,
        "containerPath": "/tmp/traefik",
        "sourceVolume": "accesslog"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.LogGroup.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "${var.environment}"
      }
    }
  }
]
  EOF

  tags = {
    Name = "traefik2.task.${var.environment}.warren.com.br"
  }
}

resource "aws_ecs_service" "Service" {
  name                               = "traefik2"
  cluster                            = var.cluster_ecs
  task_definition                    = aws_ecs_task_definition.TaskDefinition.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  propagate_tags                     = "TASK_DEFINITION"

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ECSTG.arn
    container_name   = "traefik2"
    container_port   = 8081
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ECSTG2.arn
    container_name   = "traefik2"
    container_port   = 8081
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.private_grpc_tg.arn
    container_name   = "traefik2"
    container_port   = 8081
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.public_grpc_tg.arn
    container_name   = "traefik2"
    container_port   = 8081
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.EcsSecurityGroup.id]
    subnets          = [var.private_subnets[0], var.private_subnets[1], var.private_subnets[2]]
  }

  tags = {
    Name = "traefik2.service.${var.environment}.warren.com.br"
  }
}

resource "aws_security_group" "EcsSecurityGroup" {
  name        = "${var.environment}-traefik2-sg"
  description = "Allow HTTP traffic from public"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener_rule" "ALBListenerRuleHttp" {
  listener_arn = data.terraform_remote_state.cloudformation.outputs.public_https_listener.arn
  #priority     = 46

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ECSTG.arn
  }
  condition {
    host_header {
      values = ["traefik2.${var.environment}.warren.com.br"]
    }
  }
}

resource "aws_lb_listener_rule" "ALBListenerRuleHttp2" {
  listener_arn = data.terraform_remote_state.cloudformation.outputs.internal_https_listener.arn
  #priority     = 47

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ECSTG2.arn
  }
  condition {
    host_header {
      values = ["traefik2.${var.environment}.warren.com.br"]
    }
  }
}

resource "aws_lb_listener_rule" "ALBListenerRuleGrpcPublic" {
  listener_arn = data.terraform_remote_state.cloudformation.outputs.public_https_listener.arn
  #priority     = 48

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_grpc_tg.arn
  }
  condition {
    http_header {
      http_header_name = "Content-Type"
      values           = ["application/grpc", "application/grpc-web-text", "application/grpc-web+proto", "application/grpc-web+json", "application/grpc-web+thrift"]
    }
  }
}

resource "aws_lb_listener_rule" "ALBListenerRuleGrpcInternal" {
  listener_arn = data.terraform_remote_state.cloudformation.outputs.internal_https_listener.arn
  #priority     = 49

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_grpc_tg.arn
  }
  condition {
    http_header {
      http_header_name = "Content-Type"
      values           = ["application/grpc", "application/grpc-web-text", "application/grpc-web+proto", "application/grpc-web+json", "application/grpc-web+thrift"]
    }
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = 2
  max_capacity       = var.environment == "prd" ? 10 : 5
  resource_id        = "service/${data.terraform_remote_state.cloudformation.outputs.ClusterEcs}/traefik2"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "autoscaling_target_policy" {
  depends_on         = [aws_appautoscaling_target.ecs_target]
  name               = "ECSServiceAverageMemoryUtilization:traefik2"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 50
    scale_out_cooldown = 120
    scale_in_cooldown  = 300
  }
}

resource "aws_lb_target_group" "ECSTG" {
  name        = "traefik2-public-${var.environment}-tg"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    interval            = 10
    path                = "/ping"
    port                = 8081
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_lb_target_group" "ECSTG2" {
  name        = "traefik2-private-${var.environment}-tg"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    interval            = 10
    path                = "/ping"
    port                = 8081
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_lb_target_group" "private_grpc_tg" {
  name             = "traefik-grpc-private-${var.environment}-tg"
  port             = 8081
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = var.vpc_id

  health_check {
    interval            = 10
    path                = "/AWS.ALB/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "0,12"
  }
}

resource "aws_lb_target_group" "public_grpc_tg" {
  name             = "traefik-grpc-public-${var.environment}-tg"
  port             = 8081
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = var.vpc_id

  health_check {
    interval            = 10
    path                = "/AWS.ALB/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "0,12"
  }
}

resource "aws_route53_record" "RecordPrivate" {
  for_each = toset(["traefik2", "traefik-prometheus"])
  zone_id  = var.hostedzone_private
  name     = "${each.key}.${var.environment}.warren.com.br"
  type     = "A"
  alias {
    name                   = data.terraform_remote_state.cloudformation.outputs.internal_lb.dns_name
    zone_id                = "Z35SXDOTRQ7X7K"
    evaluate_target_health = false
  }
}

output "Traefik2TGPublic" {
  value = aws_lb_target_group.ECSTG.arn
}

output "Traefik2TGPrivate" {
  value = aws_lb_target_group.ECSTG2.arn
}

output "Traefik2SG" {
  value = aws_security_group.EcsSecurityGroup.id
}
