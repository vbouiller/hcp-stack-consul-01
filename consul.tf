locals {
  consul_cluster_addr    = data.terraform_remote_state.hcp.outputs.consul_url
  consul_datacenter      = data.terraform_remote_state.hcp.outputs.consul_datacenter
  consul_root_token      = data.terraform_remote_state.hcp.outputs.consul_root_token
  hvn                    = data.terraform_remote_state.hcp.outputs.hvn
  ssh                    = true
  ssm                    = true
  install_demo_app       = true
  client_ca_file         = data.terraform_remote_state.hcp.outputs.client_ca_file
  client_config_file     = data.terraform_remote_state.hcp.outputs.client_config_file
  consul_version         = data.terraform_remote_state.hcp.outputs.consul_version
  hcp_client_id          = data.terraform_remote_state.hcp.outputs.hcp_client_id
  hcp_client_secret      = data.terraform_remote_state.hcp.outputs.hcp_client_secret
  hcp_consul_cluster_id  = data.terraform_remote_state.hcp.outputs.hcp_consul_cluster_id
}

provider "hcp" {
  client_id     = local.hcp_client_id
  client_secret = local.hcp_client_secret
}


provider "consul" {
  address    = local.consul_cluster_addr
  datacenter = local.consul_datacenter
  token      = local.consul_root_token
}

# HVN VPC Peering
module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "~> 0.8.10"

  hvn             = local.hvn
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  route_table_ids = module.vpc.public_route_table_ids
}

// Security groups
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  #vpc_id      = data.aws_vpc.selected.id
  vpc_id      = module.vpc.vpc_id


  ingress {
    description      = "SSH into instance"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

// Consul client instance
resource "aws_instance" "consul_client" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    module.aws_hcp_consul.security_group_id
  ]
  #key_name = aws_key_pair.consul_client.key_name
  key_name = var.pub_key

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/scripts/setup.sh", {
      consul_ca        = local.client_ca_file
      consul_config    = local.client_config_file
      consul_acl_token = local.consul_root_token
      consul_version   = local.consul_version
      consul_service = base64encode(templatefile("${path.module}/scripts/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      vpc_cidr = var.network_address_space
    })),
  })

  tags = {
    Name = "hcp-consul-client-${count.index}"
  }
}

# resource "tls_private_key" "ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "hcp_ec2" {
#   count = local.ssh ? 1 : 0

#   public_key = tls_private_key.ssh.public_key_openssh
#   key_name   = "hcp-ec2-key-${var.name}"
# }

# resource "local_file" "ssh_key" {
#   count = local.ssh ? 1 : 0

#   content         = tls_private_key.ssh.private_key_pem
#   file_permission = "400"
#   filename        = "${path.module}/${aws_key_pair.hcp_ec2[0].key_name}.pem"
# }

# module "aws_ec2_consul_client" {
#   source  = "hashicorp/hcp-consul/aws//modules/hcp-ec2-client"
#   version = "~> 0.8.9"

#   allowed_http_cidr_blocks = ["0.0.0.0/0"]
#   allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
#   client_ca_file           = local.client_ca_file
#   client_config_file       = local.client_config_file
#   consul_version           = local.consul_version
#   nat_public_ips           = module.vpc.nat_public_ips
#   install_demo_app         = local.install_demo_app
#   root_token               = local.consul_root_token
#   security_group_id        = module.aws_hcp_consul.security_group_id
#   ssh_keyname              = local.ssh ? aws_key_pair.hcp_ec2[0].key_name : ""
#   ssm                      = local.ssm
#   subnet_id                = module.vpc.public_subnets[0]
#   vpc_id                   = module.vpc.vpc_id
# }


# output "consul_root_token" {
#   value     = local.consul_root_token
#   sensitive = true
# }

# output "consul_url" {
#   value = local.consul_cluster_addr
# }

# output "nomad_url" {
#   value = "http://${module.aws_ec2_consul_client.public_ip}:8081"
# }

# output "hashicups_url" {
#   value = "http://${module.aws_ec2_consul_client.public_ip}"
# }

# output "next_steps" {
#   value = local.install_demo_app ? "HashiCups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token." : null
# }

# output "howto_connect" {
#   value = <<EOF
#   ${local.install_demo_app ? "The demo app, HashiCups, is installed on a Nomad server we have deployed for you." : ""}
#   ${local.install_demo_app ? "To access Nomad using your local client run the following command:" : ""}
#   ${local.install_demo_app ? "export NOMAD_HTTP_AUTH=nomad:$(terraform output consul_root_token)" : ""}
#   ${local.install_demo_app ? "export NOMAD_ADDR=http://${module.aws_ec2_consul_client.public_ip}:8081" : ""}

#   To access Consul from your local client run:
#   export CONSUL_HTTP_ADDR="${local.consul_cluster_addr}"
#   export CONSUL_HTTP_TOKEN=$(terraform output consul_root_token)
  
#   To connect to the ec2 instance deployed: 
# ${local.ssh ? "  - To access via SSH run: ssh -i ${abspath(local_file.ssh_key[0].filename)} ubuntu@${module.aws_ec2_consul_client.public_ip}" : ""}
# ${local.ssm ? "  - To access via SSM run: aws ssm start-session --target ${module.aws_ec2_consul_client.host_id} --region ${var.aws_region}" : ""}
#   EOF
# }