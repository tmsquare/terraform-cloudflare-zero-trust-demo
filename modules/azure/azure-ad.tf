#==========================================================
# Group Configuration
#==========================================================

# Create Azure AD groups with prefix "azure_"
resource "azuread_group" "azure_engineering" {
  display_name     = "Azure_engineering"
  security_enabled = true
}

resource "azuread_group" "azure_sales" {
  display_name     = "Azure_sales"
  security_enabled = true
}

#==========================================================
# Create Users
#==========================================================
resource "azuread_user" "developer1" {
  user_principal_name = "${var.azure_developer1_name}@${var.azure_user_principal_domain}"
  display_name        = var.azure_developer1_name
  mail_nickname       = var.azure_developer1_name
  password            = var.azure_user_password
}

resource "azuread_user" "developer2" {
  user_principal_name = "${var.azure_developer2_name}@${var.azure_user_principal_domain}"
  display_name        = var.azure_developer2_name
  mail_nickname       = var.azure_developer2_name
  password            = var.azure_user_password
}

resource "azuread_user" "sales1" {
  user_principal_name = "${var.azure_sales1_name}@${var.azure_user_principal_domain}"
  display_name        = var.azure_sales1_name
  mail_nickname       = var.azure_sales1_name
  password            = var.azure_user_password
}

resource "azuread_user" "sales2" {
  user_principal_name = "${var.azure_sales2_name}@${var.azure_user_principal_domain}"
  display_name        = var.azure_sales2_name
  mail_nickname       = var.azure_sales2_name
  password            = var.azure_user_password
}



#==========================================================
# Assign users to groups
#==========================================================
resource "azuread_group_member" "engineering_developer1" {
  group_object_id  = azuread_group.azure_engineering.object_id
  member_object_id = azuread_user.developer1.object_id
}

resource "azuread_group_member" "engineering_developer2" {
  group_object_id  = azuread_group.azure_engineering.object_id
  member_object_id = azuread_user.developer2.object_id
}


resource "azuread_group_member" "sales1_member" {
  group_object_id  = azuread_group.azure_sales.object_id
  member_object_id = azuread_user.sales1.object_id
}

resource "azuread_group_member" "sales2_member" {
  group_object_id  = azuread_group.azure_sales.object_id
  member_object_id = azuread_user.sales2.object_id
}

# adding matthieu to azure_sales group
resource "azuread_group_member" "matthieu_member" {
  group_object_id  = azuread_group.azure_sales.object_id
  member_object_id = var.azure_matthieu_user_object_id
}
