##### OUTPUT
output "gcp_public_keys" {
  value = {
    for username, key in tls_private_key.gcp_user_keys :
    username => local_file.gcp_public_keys[username].content # Add .content
  }
}

output "gcp_vm_key" {
  value = [for key in tls_private_key.gcp_vm_key : key.public_key_openssh]
}




output "aws_ssh_public_key" {
  value = [for key in tls_private_key.aws_ssh_key : key.public_key_openssh]
}

output "aws_ssh_service_public_key" {
  value = tls_private_key.aws_ssh_service_key.public_key_openssh
}





output "azure_ssh_public_key" {
  value = [for key in tls_private_key.azure_ssh_key : key.public_key_openssh]
}



output "gcp_vm_key_paths" {
  value = [for k in local_file.gcp_vm_private_key : k.filename]
}

output "aws_cloudflared_key_paths" {
  value = [for k in local_file.aws_private_key : k.filename]
}

output "aws_service_key_path" {
  value = local_file.aws_service_private_key.filename
}

output "azure_key_paths" {
  value = [for k in local_file.azure_private_key : k.filename]
}
