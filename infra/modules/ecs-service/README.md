<!-- BEGIN_TF_DOCS -->
# terraform auto-generated docs
## Requirements

No requirements.
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
## Modules

No modules.
## Resources

| Name | Type |
|------|------|
| [aws_appautoscaling_policy.autoscaling_target_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.scale_down_step_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.scale_up_step_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.ecs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.cpu_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.memory_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecr_lifecycle_policy.ecr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.ecs_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [external_external.task_definition](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [terraform_remote_state.base](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.traefik](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_cpu_threshold"></a> [alarm\_cpu\_threshold](#input\_alarm\_cpu\_threshold) | The value against which the specified statistic is compared | `string` | `"80"` | no |
| <a name="input_alarm_memory_threshold"></a> [alarm\_memory\_threshold](#input\_alarm\_memory\_threshold) | The value against which the specified statistic is compared | `string` | `"80"` | no |
| <a name="input_auto_scaling_down_cooldown"></a> [auto\_scaling\_down\_cooldown](#input\_auto\_scaling\_down\_cooldown) | Auto Scaling Down Cooldown | `number` | `300` | no |
| <a name="input_auto_scaling_max_capacity"></a> [auto\_scaling\_max\_capacity](#input\_auto\_scaling\_max\_capacity) | Auto Scaling Max Capacity | `number` | `4` | no |
| <a name="input_auto_scaling_metric"></a> [auto\_scaling\_metric](#input\_auto\_scaling\_metric) | Auto Scaling Metric to use | `string` | `"cpu"` | no |
| <a name="input_auto_scaling_min_capacity"></a> [auto\_scaling\_min\_capacity](#input\_auto\_scaling\_min\_capacity) | Auto Scaling Min Capacity | `number` | `1` | no |
| <a name="input_auto_scaling_target_value"></a> [auto\_scaling\_target\_value](#input\_auto\_scaling\_target\_value) | Enable Auto Scaling | `number` | `70` | no |
| <a name="input_auto_scaling_type"></a> [auto\_scaling\_type](#input\_auto\_scaling\_type) | Enable Auto Scaling | `string` | `"none"` | no |
| <a name="input_auto_scaling_up_cooldown"></a> [auto\_scaling\_up\_cooldown](#input\_auto\_scaling\_up\_cooldown) | Auto Scaling Up Cooldown | `number` | `120` | no |
| <a name="input_background_service"></a> [background\_service](#input\_background\_service) | n/a | `bool` | `false` | no |
| <a name="input_command"></a> [command](#input\_command) | Command | `list(string)` | `[]` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU | `number` | `256` | no |
| <a name="input_cpu_alarm_evaluation_periods"></a> [cpu\_alarm\_evaluation\_periods](#input\_cpu\_alarm\_evaluation\_periods) | Evaluation periods for CPU Alarm | `string` | `"2"` | no |
| <a name="input_cpu_alarm_period"></a> [cpu\_alarm\_period](#input\_cpu\_alarm\_period) | Evaluation periods for CPU Alarm | `string` | `"300"` | no |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | Entrypoint | `list(string)` | `[]` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | Object Containing Env Vars per Environment | `map` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `any` | n/a | yes |
| <a name="input_extra_policies"></a> [extra\_policies](#input\_extra\_policies) | Extra policies to add to the task role | `map(string)` | `null` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | Defines the frequency of the health check calls | `number` | `10` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | Is appended to the server URL to set the health check endpoint | `string` | `"/health"` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | Defines the maximum duration Traefik will wait for a health check request before considering the server failed (unhealthy) | `number` | `5` | no |
| <a name="input_loadbalancer_protocol"></a> [loadbalancer\_protocol](#input\_loadbalancer\_protocol) | Traefik loadBalancer protocol | `string` | `"http"` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory | `number` | `512` | no |
| <a name="input_metrics_path"></a> [metrics\_path](#input\_metrics\_path) | Path that Prometheus will use to collect metrics | `string` | `"/metrics"` | no |
| <a name="input_metrics_port"></a> [metrics\_port](#input\_metrics\_port) | Port that Prometheus will use to collect metrics | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Service name | `string` | n/a | yes |
| <a name="input_ondemand_base"></a> [ondemand\_base](#input\_ondemand\_base) | Number of base tasks on demand | `number` | `1` | no |
| <a name="input_port"></a> [port](#input\_port) | Service Port | `number` | `8080` | no |
| <a name="input_public"></a> [public](#input\_public) | n/a | `bool` | `true` | no |
| <a name="input_ratelimit_average"></a> [ratelimit\_average](#input\_ratelimit\_average) | Maximum rate, by default in requests by second, allowed for the given source (0 to no rate limiting) | `number` | `10` | no |
| <a name="input_ratelimit_burst"></a> [ratelimit\_burst](#input\_ratelimit\_burst) | Maximum number of requests allowed to go through in the same arbitrarily small period of time | `number` | `20` | no |
| <a name="input_ratelimit_ip_depth"></a> [ratelimit\_ip\_depth](#input\_ratelimit\_ip\_depth) | Use the X-Forwarded-For header and take the IP located at the depth position (starting from the right) | `number` | `1` | no |
| <a name="input_ratelimit_period"></a> [ratelimit\_period](#input\_ratelimit\_period) | In combination with ratelimit\_average, defines the actual maximum rate (r = average / period) | `string` | `"5s"` | no |
| <a name="input_stop_timeout"></a> [stop\_timeout](#input\_stop\_timeout) | Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. | `number` | `30` | no |
| <a name="input_use_spot"></a> [use\_spot](#input\_use\_spot) | n/a | `bool` | `false` | no |
## Outputs

No outputs.
<!-- END_TF_DOCS -->