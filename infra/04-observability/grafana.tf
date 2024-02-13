provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Service = "observability"
    }
  }
}

terraform {
  backend "s3" {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "grafana-prometheus"
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

data "terraform_remote_state" "traefik" {
  backend = "s3"

  config = {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "traefik"
    region = "us-east-1"
  }
}

data "external" "grafana_task_definition" {
  program = ["bash", "../modules/ecs-task-definition.sh"]
  query = {
    service   = "grafana"
    cluster   = var.environment
    path_root = jsonencode(path.root)
  }
}

resource "aws_cloudwatch_log_group" "grafana_log_group" {
  name              = "/ecs/grafana"
  retention_in_days = "60"
}

resource "aws_security_group" "grafana_security_group" {
  name        = "logging-grafana-sg"
  description = "LOGGING GRAFANA ECS SERVICE SECURITY GROUP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.traefik.outputs.traefik_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana.securitygroup.logging.desafio"
  }
}

resource "aws_security_group_rule" "grafana_efs_security_group_rule" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "FROM GRAFANA"
  source_security_group_id = aws_security_group.grafana_security_group.id
  security_group_id        = aws_security_group.efs_security_group.id
}

resource "aws_ecs_service" "grafana-service" {
  name                               = "grafana"
  cluster                            = var.environment
  task_definition                    = "${aws_ecs_task_definition.grafana_task_definition.family}:${data.external.grafana_task_definition.result["task_definition_revision"] > aws_ecs_task_definition.grafana_task_definition.revision ? data.external.grafana_task_definition.result["task_definition_revision"] : aws_ecs_task_definition.grafana_task_definition.revision}"
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  platform_version                   = "1.4.0"

  depends_on = [aws_ecs_task_definition.grafana_task_definition]

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.grafana_security_group.id]
    subnets          = data.terraform_remote_state.base.outputs.private_subnets
  }

  tags = {
    Name = "grafana.service.logging.desafio"
  }
}

resource "aws_iam_role" "iam_ecs_task_execution_role" {
  name = "${var.environment}-GrafanaEcsTaskExecutionRole"
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

resource "aws_iam_policy" "efs_policy" {
  name        = "test_policy"
  path        = "/"
  description = "EFS access from Grafana"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:*",
        ]
        Effect   = "Allow"
        Resource = aws_efs_file_system.efs_logging.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_ecs_task_execution_role_policy" {
  role       = aws_iam_role.iam_ecs_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "traefik_policy" {
  role       = aws_iam_role.iam_ecs_task_execution_role.id
  policy_arn = aws_iam_policy.efs_policy.id
}

resource "aws_ecs_task_definition" "grafana_task_definition" {
  family                   = "grafana"
  execution_role_arn       = aws_iam_role.iam_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.iam_ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  volume {
    name = "efs-storage"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs_logging.id
      root_directory = "/grafana"
    }
  }

  tags = {
    Name = "grafana.task.logging.desafio"
  }

  container_definitions = <<EOF
[
  {
    "name": "grafana",
    "image": "grafana/grafana:9.1.7",
    "essential": true,
    "cpu": 0,
    "user": "root",
    "dockerLabels": {
      "traefik.enable": "true",
      "traefik.http.services.grafana.loadbalancer.server.scheme": "http",
      "traefik.http.services.grafana.loadbalancer.server.port": "3000",
      "traefik.http.routers.grafana.rule": "Host(`grafana.sidneiweber.com.br`)"
    },
    "mountPoints": [
      {
        "containerPath": "/var/lib/grafana",
        "sourceVolume": "efs-storage"
      }
    ],
    "volumesFrom": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.grafana_log_group.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "logging"
      }
    },
    "portMappings": [
      {
        "hostPort": 3000,
        "protocol": "tcp",
        "containerPort": 3000
      }
    ],
    "secrets": [],
    "environment": [
      {
        "name": "GF_INSTALL_PLUGINS",
        "value": "grafana-clock-panel,grafana-piechart-panel,novatec-sdg-panel,alexanderzobnin-zabbix-app,redis-datasource"
      },
      {
        "name": "GF_ALLOWED_DOMAINS",
        "value": "grafana.sidneiweber.com.br"
      },
      {
        "value": "https://grafana.sidneiweber.com.br",
        "name": "GF_SERVER_ROOT_URL"
      }
    ]
  }
]
  EOF
}
