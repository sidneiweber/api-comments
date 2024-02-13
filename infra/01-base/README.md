<!-- BEGIN_TF_DOCS -->
# terraform auto-generated docs
## Requirements

No requirements.
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.36.0 |
## Modules

No modules.
## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.httpcode_lb_private_5xx_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.httpcode_lb_public_5xx_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_eip.nat_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lb.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.private_ssl_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.public_ssl_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.private_loadbalancer_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.public_loadbalancer_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_acm_certificate.certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment 3 letters identifier | `string` | n/a | yes |
| <a name="input_evaluation_period"></a> [evaluation\_period](#input\_evaluation\_period) | The evaluation period over which to use when triggering alarms. | `string` | `"5"` | no |
| <a name="input_private_subnets_cidrs"></a> [private\_subnets\_cidrs](#input\_private\_subnets\_cidrs) | n/a | `list(string)` | n/a | yes |
| <a name="input_public_subnets_cidrs"></a> [public\_subnets\_cidrs](#input\_public\_subnets\_cidrs) | n/a | `list(string)` | n/a | yes |
| <a name="input_statistic_period"></a> [statistic\_period](#input\_statistic\_period) | The number of seconds that make each statistic period. | `string` | `"60"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | n/a | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_listener_arn"></a> [private\_listener\_arn](#output\_private\_listener\_arn) | n/a |
| <a name="output_private_loadbalancer_arn_suffix"></a> [private\_loadbalancer\_arn\_suffix](#output\_private\_loadbalancer\_arn\_suffix) | n/a |
| <a name="output_private_loadbalancer_dns"></a> [private\_loadbalancer\_dns](#output\_private\_loadbalancer\_dns) | n/a |
| <a name="output_private_loadbalancer_sg"></a> [private\_loadbalancer\_sg](#output\_private\_loadbalancer\_sg) | n/a |
| <a name="output_private_loadbalancer_zone_id"></a> [private\_loadbalancer\_zone\_id](#output\_private\_loadbalancer\_zone\_id) | n/a |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_listener_arn"></a> [public\_listener\_arn](#output\_public\_listener\_arn) | n/a |
| <a name="output_public_loadbalancer_arn_suffix"></a> [public\_loadbalancer\_arn\_suffix](#output\_public\_loadbalancer\_arn\_suffix) | n/a |
| <a name="output_public_loadbalancer_dns"></a> [public\_loadbalancer\_dns](#output\_public\_loadbalancer\_dns) | n/a |
| <a name="output_public_loadbalancer_sg"></a> [public\_loadbalancer\_sg](#output\_public\_loadbalancer\_sg) | n/a |
| <a name="output_public_loadbalancer_zone_id"></a> [public\_loadbalancer\_zone\_id](#output\_public\_loadbalancer\_zone\_id) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->