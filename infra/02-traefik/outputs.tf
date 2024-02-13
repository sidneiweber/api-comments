output "traefik_targetgroup_public" {
  value = aws_lb_target_group.ecs_targetgroup_public.arn
}

output "traefik_targetgroup_private" {
  value = aws_lb_target_group.ecs_targetgroup_private.arn
}

output "traefik_security_group" {
  value = aws_security_group.ecs_security_group.id
}