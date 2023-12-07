# output "Bastionhost_public_IP" {
#   value = "ssh ${var.ssh_user}@${aws_instance.bastionhost.public_ip}"
# }

# output "inventory" {
#   value = data.template_file.ansible_skeleton.rendered
# }

# output "ansible_hosts" {
#   value = data.template_file.ansible_web_hosts.*.rendered
# }

# output "web_node_ips" {
#   value = aws_instance.web_nodes.*.private_ip
# }


output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "AWS VPC ID"
}

output "vpc_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "AWS VPC CIDR block"
}

output "subnet_id" {
  value       = module.vpc.public_subnets[0]
  description = "AWS public subnet"
}

output "hcp_consul_cluster_id" {
  value       = local.hcp_consul_cluster_id
  description = "HCP Consul ID"
}

output "hcp_consul_security_group" {
  value       = module.aws_hcp_consul.security_group_id
  description = "AWS Security group for HCP Consul"
}

output "ec2_client" {
  value       = aws_instance.consul_client[0].public_ip
  description = "EC2 public IP"
}



# output "ca_public_key" {
#   value = tls_private_key.signing-key.public_key_openssh
# }

# output "vault_boundary_token" {
#   value = vault_token.boundary-credentials-store-token.client_token
#   sensitive = true
# }

# output "vault_admin_token" {
#   value = local.vault_admin_token
# }

# output "activation_token" {
#   value = boundary_worker.controller_led.controller_generated_activation_token
# }

# output "boundary_cluster" {
#   value = local.boundary_cluster_addr
# }

