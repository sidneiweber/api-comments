provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment
      Service     = "Base"
    }
  }
}

terraform {
  backend "s3" {
    #bucket = "terraform.BUCKETENVIRONMENT.desafio"
    bucket = "terraform.dev.desafio"
    key    = "base"
    region = "us-east-1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_acm_certificate" "certificate" {
  domain      = "sidneiweber.com.br"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "vpc.${var.environment}.desafio"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = { for idx, cidr_block in var.public_subnets_cidrs : idx => cidr_block }

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  availability_zone = data.aws_availability_zones.available.names[each.key]

  tags = {
    Name = "public-${substr(data.aws_availability_zones.available.names[each.key], -1, 1)}.subnet.${var.environment}.desafio"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = { for idx, cidr_block in var.private_subnets_cidrs : idx => cidr_block }

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  availability_zone       = data.aws_availability_zones.available.names[each.key]
  map_public_ip_on_launch = false


  tags = {
    Name = "private-${substr(data.aws_availability_zones.available.names[each.key], -1, 1)}.subnet.${var.environment}.desafio"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public.routetable.${var.environment}.desafio"
  }
}

resource "aws_route_table_association" "public_association" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gw.${var.environment}.desafio"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private.routetable.${var.environment}.desafio"
  }
}

resource "aws_route_table_association" "private_association" {
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_eip" "nat_ip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "nat.eip.${var.environment}.desafio"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "nat.${var.environment}.desafio"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_security_group" "public_loadbalancer_sg" {
  name        = "${var.environment}-public-loadbalancer-sg"
  description = "${var.environment} PUBLIC LB SECURITY GROUP"
  vpc_id      = aws_vpc.main.id

  lifecycle { ignore_changes = [ingress] }

  ingress {
    description = "Allow all traffic"
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

resource "aws_lb" "public" {
  name               = "public-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_loadbalancer_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

  enable_deletion_protection = true

  tags = {
    Name = "public-lb.${var.environment}.desafio"
  }
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "public_ssl_listener" {
  load_balancer_arn = aws_lb.public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group" "private_loadbalancer_sg" {
  name        = "${var.environment}-private-loadbalancer-sg"
  description = "${var.environment} PRIVATE LB SECURITY GROUP"
  vpc_id      = aws_vpc.main.id

  lifecycle { ignore_changes = [ingress] }

  ingress {
    description = "Allow all traffic"
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

resource "aws_lb" "private" {
  name               = "private-loadbalancer"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_loadbalancer_sg.id]
  subnets            = [for subnet in aws_subnet.private_subnet : subnet.id]

  enable_deletion_protection = true

  tags = {
    Name = "private-lb.${var.environment}.desafio"
  }
}

resource "aws_lb_listener" "private" {
  load_balancer_arn = aws_lb.private.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "private_ssl_listener" {
  load_balancer_arn = aws_lb.private.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "httpcode_lb_private_5xx_count" {
  count               = var.environment == "prd" ? 1 : 0
  alarm_name          = "alb-private-high5XXCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_period
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.statistic_period
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Average API 5XX load balancer error code count is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    "LoadBalancer" = aws_lb.private.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "httpcode_lb_public_5xx_count" {
  count               = var.environment == "prd" ? 1 : 0
  alarm_name          = "alb-public-high5XXCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_period
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.statistic_period
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Average API 5XX load balancer error code count is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    "LoadBalancer" = aws_lb.public.arn_suffix
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.environment

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "ecs-cluster.${var.environment}.desafio"
  }
}