output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = values(aws_subnet.public_subnet).*.id
}

output "private_subnets" {
  value = values(aws_subnet.private_subnet).*.id
}

output "public_loadbalancer_sg" {
  value = aws_security_group.public_loadbalancer_sg.id
}

output "public_loadbalancer_dns" {
  value = aws_lb.public.dns_name
}

output "public_loadbalancer_zone_id" {
  value = aws_lb.public.zone_id
}

output "public_listener_arn" {
  value = aws_lb_listener.public_ssl_listener.arn
}

output "private_loadbalancer_sg" {
  value = aws_security_group.private_loadbalancer_sg.id
}

output "private_loadbalancer_dns" {
  value = aws_lb.private.dns_name
}

output "private_loadbalancer_zone_id" {
  value = aws_lb.private.zone_id
}

output "private_listener_arn" {
  value = aws_lb_listener.private_ssl_listener.arn
}

output "private_loadbalancer_arn_suffix" {
  value = aws_lb.private.arn_suffix
}

output "public_loadbalancer_arn_suffix" {
  value = aws_lb.public.arn_suffix
}