#======================================================
# Block pdf file download for everyone
#======================================================
resource "cloudflare_zero_trust_gateway_policy" "block_pdf_file_download_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Block PDF Files download"
  description = "Block Downloading PDF Files"
  enabled     = true
  action      = "block"
  precedence  = "67"

  filters = ["http"]

  traffic  = "any(http.download.file.types[*] in {\"pdf\"})"
  identity = "any(identity.saml_attributes[*] == \"groups=${var.okta_salesengineering_saml_group_name}\")"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This download is blocked because it is a pdf file (not approved)"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This download is blocked because it is a pdf file (not approved)"
    }
  }
}



#=============================================================
# Block access to gambling site for everyone but Contractors
#=============================================================
resource "cloudflare_zero_trust_gateway_policy" "block_gambling_site_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Block Gambling websites"
  description = "Block Gambling website according to corporate policies (HTTP)."
  enabled     = true
  action      = "block"
  precedence  = "168"

  filters = ["http"]

  traffic  = "any(http.request.uri.content_category[*] in {99})"
  identity = "not(any(identity.groups.name[*] in {\"${var.okta_contractors_saml_group_name}\"})) or not(identity.email == \"${var.okta_bob_user_login}\")"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked according to corporate policies (HTTP)"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked according to corporate policies (HTTP)"
    }
  }
}



#=======================================================================================
# Block access via IP addresses and port to Application Competition and Administration
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_ip_access_to_internal_app_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Blocking access to private services via ip addresses on GCP"
  description = "This rule blocks the access of Competition App and Administration App via ip address and port"
  enabled     = true
  action      = "block"
  precedence  = "230"

  filters = ["l4"]

  traffic = "(net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_administration_web_app_port}) or (net.dst.ip == ${var.gcp_vm_internal_ip} and net.dst.port == ${var.cf_sensitive_web_app_port})"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked because you are trying to acces an internal app via it's IP address"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked because you are trying to acces an internal app via it's IP address"
    }
  }
}



#=======================================================================================
# Block access to setup pages in Salesforce.com
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_setup_page_sfdc_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Block Access to \"Setup\" in Salesforce"
  description = "Block the access to \"setup\" in salesforce.com"
  enabled     = true
  action      = "block"
  precedence  = "83"

  filters = ["http"]

  traffic = "http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/home?setupApp=all\" or http.request.uri == \"https://power-business-8049.lightning.force.com/lightning/setup/SetupOneHome/home\""

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "You are not allowed to access setup page on SFDC"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "You are not allowed to access setup page on SFDC"
    }
  }
}



#=======================================================================================
# Block Popular AI Tools
#=======================================================================================
resource "cloudflare_zero_trust_gateway_policy" "block_ai_tools_policy" {
  account_id  = var.cloudflare_account_id
  name        = "Block Access to popular AI Tools"
  description = "This rule blocks access to popular AI Tools"
  enabled     = false
  action      = "block"
  precedence  = "130"

  filters = ["http"]

  traffic = "any(app.type.ids[*] in {25})"

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked because it is considered an AI Tool not approved"
    ip_categories                      = false
    ip_indicator_feeds                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked because it is considered an AI Tool not approved"
    }
  }
}

#=======================================================================================
# Gateway Network Policy: Windows RDP Server
#=======================================================================================
# Allow RDP for IT Admins
resource "cloudflare_zero_trust_gateway_policy" "rdp_admin_access_policy" {
  account_id  = var.cloudflare_account_id
  name        = "RDP - IT Admin Access Policy"
  description = "Allow RDP access for IT administrators"
  enabled     = true
  action      = "allow"
  precedence  = "2"

  filters = ["l4"]

  traffic        = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""
  identity       = "any(identity.saml_attributes[*] == \"groups=${var.okta_itadmin_saml_group_name}\") or any(identity.saml_attributes[*] == \"groups=${var.okta_infrastructureadmin_saml_group_name}\")"
  device_posture = "any(device_posture.checks.passed[*] == \"${var.cf_latest_macOS_version_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_latest_windows_version_posture_id}\") or any(device_posture.checks.passed[*] == \"${var.cf_latest_linux_kernel_version_posture_id}\")"

  rule_settings = {
    block_page_enabled                 = false
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = false
    }
  }
}

# Block all other RDP access
resource "cloudflare_zero_trust_gateway_policy" "rdp_default_deny_policy" {
  account_id  = var.cloudflare_account_id
  name        = "RDP - Default Deny Policy"
  description = "Deny RDP access for others"
  enabled     = true
  action      = "block"
  precedence  = "999"

  filters = ["l4"]

  traffic = "net.dst.ip == ${var.gcp_windows_vm_internal_ip} and net.dst.port == ${var.cf_domain_controller_rdp_port} and net.protocol == \"tcp\""

  rule_settings = {
    block_page_enabled                 = false
    block_reason                       = "This website is blocked by RDP - Default Deny Policy"
    insecure_disable_dnssec_validation = false
    notification_settings = {
      enabled = true
      msg     = "This website is blocked by RDP - Default Deny Policy"
    }
  }
}
