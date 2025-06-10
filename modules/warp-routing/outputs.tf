output "cf_azure_json_subnet_generation" {
  value     = null_resource.python_script_azure_infrastructure
  sensitive = false
}

output "cf_gcp_json_subnet_generation" {
  value     = null_resource.python_script_gcp_infrastructure_warp
  sensitive = false
}

output "cf_aws_json_subnet_generation" {
  value     = null_resource.python_script_aws_infrastructure
  sensitive = false
}
