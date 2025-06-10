output "azure_engineering_group_id" {
  description = "Group ID for engineering"
  value       = azuread_group.azure_engineering.object_id
}

output "azure_sales_group_id" {
  description = "Group ID for Sales"
  value       = azuread_group.azure_sales.object_id
}
