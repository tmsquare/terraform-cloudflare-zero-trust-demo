variable "azure_user_password" {
  description = "Password for Azure AD users"
  type        = string
}

variable "azure_user_principal_domain" {
  description = "Domain for users created in Azure AD"
  type        = string
}

variable "azure_developer1_name" {
  description = "User 1 in Azure AD"
  type        = string
}

variable "azure_developer2_name" {
  description = "User 1 in Azure AD"
  type        = string
}

variable "azure_sales1_name" {
  description = "User 1 in Azure AD"
  type        = string
}

variable "azure_sales2_name" {
  description = "User 1 in Azure AD"
  type        = string
}

variable "azure_matthieu_user_object_id" {
  description = "Object ID in Azure for user Matthieu"
  type        = string
  sensitive   = true
}
