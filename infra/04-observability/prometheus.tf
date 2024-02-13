data "aws_caller_identity" "current" {}

data "external" "prometheus_task_definition" {
  program = ["bash", "../modules/ecs-task-definition.sh"]
  query = {
    service   = "prometheus"
    cluster   = var.environment
    path_root = jsonencode(path.root)
  }
}

resource "aws_cloudwatch_log_group" "prometheus_log_group" {
  name              = "/ecs/prometheus"
  retention_in_days = "60"
}

resource "aws_ecr_repository" "ecr_repository" {
  name = "logging"
}

resource "aws_security_group" "prometheus_security_group" {
  name        = "logging-prometheus-sg"
  description = "LOGGING PROMETHEUS ECS SERVICE SECURITY GROUP"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    description     = "FROM LOGGING LB"
    security_groups = [data.terraform_remote_state.traefik.outputs.traefik_security_group]
  }

  ingress {
    from_port       = 9091
    to_port         = 9091
    protocol        = "tcp"
    description     = "FROM LOGGING LB"
    security_groups = [data.terraform_remote_state.traefik.outputs.traefik_security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "prometheus.securitygroup.logging.desafio"
    Service = "Prometheus"
  }
}

resource "aws_security_group_rule" "prometheus_efs_security_group_rule" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  description              = "FROM PROMETHEUS"
  source_security_group_id = aws_security_group.prometheus_security_group.id
  security_group_id        = aws_security_group.efs_security_group.id
}

resource "aws_iam_role" "prometheus_role" {
  name = "logging-PrometheusRole"
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

resource "aws_iam_role_policy_attachment" "prometheus_role_policy_attachment" {
  role       = aws_iam_role.prometheus_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "allow_ecs_access" {
  name = "AllowPrometheusEcsAccessPolicy"
  role = aws_iam_role.prometheus_role.id

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:ListClusters",
        "ecs:ListTasks",
        "ecs:DescribeTask",
        "ec2:DescribeInstances",
        "ecs:DescribeContainerInstances",
        "ecs:DescribeTasks",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_ecs_service" "prometheus-service" {
  name                               = "prometheus"
  cluster                            = var.environment
  task_definition                    = "${aws_ecs_task_definition.prometheus_task_definition.family}:${data.external.prometheus_task_definition.result["task_definition_revision"] > aws_ecs_task_definition.prometheus_task_definition.revision ? data.external.prometheus_task_definition.result["task_definition_revision"] : aws_ecs_task_definition.prometheus_task_definition.revision}"
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50
  desired_count                      = 1
  platform_version                   = "1.4.0"

  depends_on = [aws_ecs_task_definition.prometheus_task_definition]

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.prometheus_security_group.id]
    subnets          = data.terraform_remote_state.base.outputs.private_subnets
  }

  tags = {
    Name    = "prometheus.service.logging.desafio"
    Service = "Prometheus"
  }
}

resource "aws_ecs_task_definition" "prometheus_task_definition" {
  family                   = "prometheus"
  execution_role_arn       = aws_iam_role.prometheus_role.arn
  task_role_arn            = aws_iam_role.prometheus_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  volume {
    name = "efs-storage"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs_logging.id
      root_directory = "/prometheus"
    }
  }

  tags = {
    Name    = "prometheus.task.logging.desafio"
    Service = "Prometheus"
  }

  container_definitions = <<EOF
[
  {
    "name": "prometheus",
    "image": "685496751393.dkr.ecr.us-east-1.amazonaws.com/logging:latest",
    "essential": true,
    "cpu": 0,
    "user": "root",
    "dockerLabels": {
      "traefik.enable": "true",
      "traefik.http.services.prometheus.loadbalancer.server.scheme": "http",
      "traefik.http.services.prometheus.loadbalancer.server.port": "9090",
      "traefik.http.routers.prometheus.rule": "Host(`prometheus.sidneiweber.com.br`)"
    },
    "mountPoints": [
      {
        "containerPath": "/prometheus/",
        "sourceVolume": "efs-storage"
      }
    ],
    "volumesFrom": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.prometheus_log_group.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "logging"
      }
    },
    "portMappings": [
      {
        "hostPort": 9090,
        "protocol": "tcp",
        "containerPort": 9090
      }
    ]
  },
  {
    "name": "prometheus-scan-ecs",
    "image": "tkgregory/prometheus-ecs-discovery",
    "essential": true,
    "cpu": 0,
    "command": ["-config.write-to=/prometheus/ecs_file_sd.yml"],
    "user": "root",
    "mountPoints": [
      {
        "containerPath": "/prometheus",
        "sourceVolume": "efs-storage"
      }
    ],
    "volumesFrom": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.prometheus_log_group.name}",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "logging"
      }
    }
  }
]
  EOF
}

output "prometheus_security_group" {
  value = {
    account = data.aws_caller_identity.current.account_id,
    id      = aws_security_group.prometheus_security_group.id
  }
  description = "The Prometheus security group"
}
