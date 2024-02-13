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
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "traefik"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "base" {
  backend = "s3"

  config = {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "base"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.environment
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/traefik"
  retention_in_days = var.environment == "prd" ? "60" : "14"
}

resource "aws_iam_policy" "policy" {
  name = "${var.environment}-traefik"
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

resource "aws_iam_role" "task_role" {
  name = "${var.environment}-traefik"
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

resource "aws_iam_role" "iam_ecs_task_execution_role" {
  name = "${var.environment}-traefikEcsTaskExecutionRole"
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

resource "aws_iam_role_policy_attachment" "amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.iam_ecs_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "traefik_policy" {
  role       = aws_iam_role.task_role.id
  policy_arn = aws_iam_policy.policy.id
}

resource "aws_iam_instance_profile" "iam_cloudwatch_instance_profile" {
  name = "${var.environment}_ecs_instance_profile"
  role = aws_iam_role.iam_ecs_task_execution_role.name
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "traefik"
  execution_role_arn       = aws_iam_role.iam_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
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
    "name": "traefik",
    "image": "${var.ecs_image}",
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
        "value": "${data.aws_ecs_cluster.cluster.cluster_name}"
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
      "traefik.http.routers.traefik.rule": "Host(`traefik.sidneiweber.com.br`)",
      "traefik.enable": "true",
      "traefik.http.services.traefik.loadbalancer.server.scheme": "http",
      "traefik.http.routers.traefik.middlewares": "traefik@ecs",
      "traefik.http.routers.traefik.service": "traefik@ecs",
      "traefik.http.middlewares.traefik.ratelimit.average": "0",
      "traefik.http.middlewares.traefik.ratelimit.burst": "20",
      "traefik.http.middlewares.traefik.ratelimit.period": "5s",
      "traefik.http.middlewares.traefik.ratelimit.sourcecriterion.ipstrategy.depth": "1",
      "traefik.http.services.traefik-prometheus.loadbalancer.server.port": "8082",
      "traefik.http.routers.traefik-prometheus.rule": "Host(`traefik-prometheus.sidneiweber.com.br`)",
      "traefik.http.services.traefik-prometheus.loadbalancer.server.scheme": "http",
      "traefik.http.routers.traefik-prometheus.service": "traefik-prometheus@ecs",
      "PROMETHEUS_EXPORTER_PATH": "/metrics",
      "PROMETHEUS_EXPORTER_PORT": "8082"
    },
    "privileged": null
  }
]
  EOF

  tags = {
    Name = "traefik.task.${var.environment}.desafio"
  }
}

resource "aws_ecs_service" "service" {
  name                               = "traefik"
  cluster                            = data.aws_ecs_cluster.cluster.cluster_name
  task_definition                    = aws_ecs_task_definition.task_definition.arn
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  propagate_tags                     = "TASK_DEFINITION"

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_targetgroup_public.arn
    container_name   = "traefik"
    container_port   = 8081
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_targetgroup_private.arn
    container_name   = "traefik"
    container_port   = 8081
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_security_group.id]
    subnets          = data.terraform_remote_state.base.outputs.private_subnets
  }

  tags = {
    Name = "traefik.service.${var.environment}.desafio"
  }
}

resource "aws_security_group" "ecs_security_group" {
  name        = "${var.environment}-traefik-sg"
  description = "Allow HTTP traffic from public"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

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

resource "aws_lb_listener_rule" "alb_listener_rule_http_public" {
  listener_arn = data.terraform_remote_state.base.outputs.public_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_targetgroup_public.arn
  }
  condition {
    host_header {
      values = ["*.sidneiweber.com.br"]
    }
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule_http_private" {
  listener_arn = data.terraform_remote_state.base.outputs.private_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_targetgroup_private.arn
  }
  condition {
    host_header {
      values = ["*.sidneiweber.com.br"]
    }
  }
}

resource "aws_lb_target_group" "ecs_targetgroup_public" {
  name        = "traefik-public-${var.environment}-tg"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

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

resource "aws_lb_target_group" "ecs_targetgroup_private" {
  name        = "traefik-private-${var.environment}-tg"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

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
