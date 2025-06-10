#==================================================
# Rule Groups
#===================================================
resource "cloudflare_zero_trust_access_group" "contractors_rule_group" {
  account_id = var.cloudflare_account_id
  name       = var.okta_contractors_saml_group_name

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = var.okta_contractors_saml_group_name
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "infrastructure_admin_rule_group" {
  account_id = var.cloudflare_account_id
  name       = var.okta_infrastructureadmin_saml_group_name

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = var.okta_infrastructureadmin_saml_group_name
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "sales_engineering_rule_group" {
  account_id = var.cloudflare_account_id
  name       = var.okta_salesengineering_saml_group_name

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = var.okta_salesengineering_saml_group_name
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "sales_rule_group" {
  account_id = var.cloudflare_account_id
  name       = var.okta_sales_saml_group_name

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = var.okta_sales_saml_group_name
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "it_admin_rule_group" {
  account_id = var.cloudflare_account_id
  name       = var.okta_itadmin_saml_group_name

  include = [{
    saml = {
      identity_provider_id = var.cf_okta_identity_provider_id
      attribute_name       = "groups"
      attribute_value      = var.okta_itadmin_saml_group_name
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "country_requirements_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Country Requirements"

  include = [
    {
      geo = {
        country_code = "FR"
      }
    },
    {
      geo = {
        country_code = "DE"
      }
    },
    {
      geo = {
        country_code = "US"
      }
    },
    {
      geo = {
        country_code = "GB"
      }
    }
  ]
  exclude = [
    {
      geo = {
        country_code = "CN"
      }
    },
    {
      geo = {
        country_code = "RU"
      }
    }
  ]
}


resource "cloudflare_zero_trust_access_group" "latest_os_version_requirements_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Latest OS Version Requirements"

  include = [
    {
      device_posture = {
        integration_uid = var.cf_latest_linux_kernel_version_posture_id
      }
    },
    {
      device_posture = {
        integration_uid = var.cf_latest_macOS_version_posture_id
      }
    },
    {
      device_posture = {
        integration_uid = var.cf_latest_windows_version_posture_id
      }
    }
  ]
}

resource "cloudflare_zero_trust_access_group" "employees_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Employees"

  include = [
    {
      group = {
        id = cloudflare_zero_trust_access_group.it_admin_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.sales_engineering_rule_group.id
      }
    },
    {
      group = {
        id = cloudflare_zero_trust_access_group.infrastructure_admin_rule_group.id
      }
    },
  ]
}

######### AZURE ########

resource "cloudflare_zero_trust_access_group" "azure_engineering_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Azure Engineering"

  include = [{
    azure_ad = {
      identity_provider_id = var.cf_azure_identity_provider_id
      id                   = var.azure_engineering_group_id
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "azure_sales_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Azure Sales"

  include = [{
    azure_ad = {
      identity_provider_id = var.cf_azure_identity_provider_id
      id                   = var.azure_sales_group_id
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "azure_administrators_rule_group" {
  account_id = var.cloudflare_account_id
  name       = "Azure Administrators"

  include = [{
    azure_ad = {
      identity_provider_id = var.cf_azure_identity_provider_id
      id                   = var.cf_azure_administrators_rule_group_id
    }
  }]
}
