variable "gcp_cloudflared_vm_instance" {
  type = any
}

variable "gcp_vm_instance" {
  type = list(any)
}


# Networking
variable "azure_address_prefixes" {
  description = "azure subnet prefixes"
  type        = string
}


variable "gcp_ip_cidr_infra" {
  description = "CIDR Range for GCP VMs running cloudflared"
  type        = string
}

variable "gcp_ip_cidr_warp" {
  description = "CIDR Range for GCP VMs running warp"
  type        = string
}

variable "gcp_ip_cidr_windows_rdp" {
  description = "CIDR Range for GCP VMs running cloudflared, Windows and RDP Server"
  type        = string
}

variable "aws_private_subnet_cidr" {
  description = "AWS public subnet"
  type        = string
}
