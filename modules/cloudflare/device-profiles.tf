#==========================================================
# Update to the Laest macos version
#==========================================================
resource "null_resource" "update_macos_version_rule" {
  triggers = {
    script_hash = filesha256("${path.module}/scripts/latest_osx_version_posture.sh")
    always_run  = timestamp()
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/latest_osx_version_posture.sh && ${path.module}/scripts/latest_osx_version_posture.sh"

    environment = {
      CLOUDFLARE_ACCOUNT_ID      = var.cloudflare_account_id
      CLOUDFLARE_API_KEY         = var.cloudflare_api_key
      CLOUDFLARE_POSTURE_RULE_ID = var.cf_osx_version_posture_rule_id
      CLOUDFLARE_EMAIL           = var.cloudflare_email
    }
  }
}



#==========================================================
# Get Routes from Default Profile
#==========================================================
data "cloudflare_zero_trust_device_default_profile" "main" {
  account_id = var.cloudflare_account_id
}

data "local_file" "azure_config" {
  filename   = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_azure_internal_subnet.json"
  depends_on = [var.cf_azure_json_subnet_generation]
}

data "local_file" "gcp_config" {
  filename   = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_gcp_internal_subnet.json"
  depends_on = [var.cf_gcp_json_subnet_generation]
}

data "local_file" "aws_config" {
  filename   = "${path.root}/modules/warp-routing/output/warp_subnets_including_all_except_aws_internal_subnet.json"
  depends_on = [var.cf_aws_json_subnet_generation]
}

locals {
  # Load configurations from remaining JSON files
  azure_config = jsondecode(data.local_file.azure_config.content)
  gcp_config   = jsondecode(data.local_file.gcp_config.content)
  aws_config   = jsondecode(data.local_file.aws_config.content)

  # Process Azure routes excluding base network
  azure_routes = {
    for exclusion in local.azure_config.exclusions :
    exclusion.address => {
      address     = exclusion.address
      description = exclusion.description
    } if exclusion.address != local.azure_config.metadata.base_network
  }

  # Process GCP routes excluding base network
  gcp_routes = {
    for exclusion in local.gcp_config.exclusions :
    exclusion.address => {
      address     = exclusion.address
      description = exclusion.description
    } if exclusion.address != local.gcp_config.metadata.base_network
  }

  # Process AWS routes excluding base network
  aws_routes = {
    for exclusion in local.aws_config.exclusions :
    exclusion.address => {
      address     = exclusion.address
      description = exclusion.description
    } if exclusion.address != local.aws_config.metadata.base_network
  }

  # Convert list variables to usable formats
  default_cgnat_addresses = toset([
    for route in var.cf_default_cgnat_routes : route.address
  ])

  custom_cgnat_map = {
    for route in var.cf_custom_cgnat_routes : route.address => route
  }

  # Process default routes with exclusions
  default_routes = {
    for route in data.cloudflare_zero_trust_device_default_profile.main.exclude :
    route.address => {
      address     = route.address
      description = route.description
      } if !contains([
        local.azure_config.metadata.base_network,
        local.gcp_config.metadata.base_network,
        local.aws_config.metadata.base_network
    ], route.address) && !contains(local.default_cgnat_addresses, route.address)
  }

  # Final merged configuration with precedence
  final_exclude_routes = merge(
    local.default_routes,  # Base routes
    local.azure_routes,    # Azure exceptions
    local.gcp_routes,      # GCP exceptions
    local.aws_routes,      # AWS exceptions
    local.custom_cgnat_map # Custom CGNAT ranges
  )
}


#============================================================================
# Random integer to be used for "precedence in Customized profile for demo
#============================================================================
resource "random_integer" "client_precedence" {
  min = 1
  max = 10
  keepers = {
    profile_name = "client-profile"
  }
}

resource "random_integer" "vm_precedence" {
  min = 11
  max = 20
  keepers = {
    profile_name = "vm-profile"
  }
}

resource "random_integer" "warp_precedence" {
  min = 21
  max = 30
  keepers = {
    profile_name = "warp-profile"
  }
}



#==========================================================
# Customized profile for demo to be used on local laptop
#==========================================================
resource "cloudflare_zero_trust_device_custom_profile" "client_custom_route_profile" {
  account_id = var.cloudflare_account_id
  enabled    = true

  name                  = "Zero-Trust demo local laptop (mac)"
  description           = "This profile is for the local laptop (running macos) for my zero-trust demo"
  precedence            = random_integer.client_precedence.result
  match                 = "os.name == \"${var.cf_device_os}\""
  allow_mode_switch     = false
  tunnel_protocol       = "masque"
  switch_locked         = false
  allowed_to_leave      = true
  allow_updates         = true
  auto_connect          = 0
  disable_auto_fallback = false
  support_url           = "Zero-TrustDemo-LaptopProfile"
  service_mode_v2 = {
    mode = "warp"
  }

  # Exclude routes configuration
  exclude = [for route in values(local.final_exclude_routes) : {
    address     = route.address
    description = route.description
  }]

  # Fallback domains configuration
  # fallback_domains = [
  #   for domain in var.cf_default_fallback_domains : {
  #     suffix      = domain.suffix
  #     dns_server  = domain.dns_server
  #     description = domain.description
  #   }
  # ]

  lan_allow_minutes     = 30
  lan_allow_subnet_size = 16
  exclude_office_ips    = true
  captive_portal        = 180
}



#=======================================================
# Customized profile for demo to be used in local VMs
#========================================================
resource "cloudflare_zero_trust_device_custom_profile" "vms_custom_route_profile" {
  account_id = var.cloudflare_account_id
  enabled    = true

  name                  = "Zero-Trust demo VMs (Ubuntu and Windows 11)"
  description           = "This profile is for my VMs for my zero-trust demo"
  precedence            = random_integer.vm_precedence.result
  match                 = "any(identity.saml_attributes[*] in {\"groups=${var.okta_infrastructureadmin_saml_group_name}\"}) or any(identity.saml_attributes[*] in {\"groups=${var.okta_contractors_saml_group_name}\"}) or identity.email matches \"${var.cf_email_domain}\""
  allow_mode_switch     = false
  tunnel_protocol       = "masque"
  switch_locked         = false
  allowed_to_leave      = true
  allow_updates         = true
  auto_connect          = 0
  disable_auto_fallback = false
  support_url           = "Zero-TrustDemo-VMProfile"

  service_mode_v2 = {
    mode = "warp"
  }

  # Exclude routes configuration
  exclude = [for route in values(local.final_exclude_routes) : {
    address     = route.address
    description = route.description
  }]

  # Fallback domains configuration
  # fallback_domains = [
  #   for domain in var.cf_default_fallback_domains : {
  #     suffix      = domain.suffix
  #     dns_server  = domain.dns_server
  #     description = domain.description
  #   }
  # ]

  lan_allow_minutes     = 30
  lan_allow_subnet_size = 16
  exclude_office_ips    = true
  captive_portal        = 180
}



#===============================================================
# Customized profile for demo to be used in WARP Connector
#===============================================================
resource "cloudflare_zero_trust_device_custom_profile" "warpconnector_custom_route_profile" {
  account_id = var.cloudflare_account_id
  enabled    = true

  name                  = "Zero-Trust demo WarpConnector"
  description           = "This profile is dedicated for WARP Connector"
  precedence            = random_integer.warp_precedence.result
  match                 = "identity.email == \"warp_connector@${var.cf_team_name}.cloudflareaccess.com\""
  allow_mode_switch     = false
  tunnel_protocol       = "masque"
  switch_locked         = false
  allowed_to_leave      = true
  allow_updates         = true
  auto_connect          = 0
  disable_auto_fallback = false
  support_url           = "WARPConnectorProfile"
  service_mode_v2 = {
    mode = "warp"
  }

  # Exclude routes configuration
  exclude = [
    for route in local.final_exclude_routes : {
      address     = route.address
      description = route.description
    }
  ]

  # Fallback domains configuration
  # fallback_domains = [
  #   for domain in var.cf_default_fallback_domains : {
  #     suffix      = domain.suffix
  #     dns_server  = domain.dns_server
  #     description = domain.description
  #   }
  # ]

  lan_allow_minutes     = 30
  lan_allow_subnet_size = 16
  exclude_office_ips    = true
  captive_portal        = 180
}
