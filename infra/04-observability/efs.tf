resource "aws_security_group" "efs_security_group" {
  name        = "logging-efs-sg"
  description = "Allow EFS traffic from private"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "efs.securitygroup.logging.desafio"
    Service = "EFS"
  }
}

resource "aws_efs_file_system" "efs_logging" {
  creation_token = "logging"

  tags = {
    Name    = "efs-logging.desafio"
    Service = "EFS"
  }
}

resource "aws_efs_mount_target" "mount_target_a" {
  file_system_id  = aws_efs_file_system.efs_logging.id
  subnet_id       = data.terraform_remote_state.base.outputs.private_subnets[0]
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "mount_target_c" {
  file_system_id  = aws_efs_file_system.efs_logging.id
  subnet_id       = data.terraform_remote_state.base.outputs.private_subnets[1]
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "mount_target_e" {
  file_system_id  = aws_efs_file_system.efs_logging.id
  subnet_id       = data.terraform_remote_state.base.outputs.private_subnets[2]
  security_groups = [aws_security_group.efs_security_group.id]
}