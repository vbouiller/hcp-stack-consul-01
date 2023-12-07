data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = var.tfc_state_org
    workspaces = {
      name = var.rs_platform_hcp
    }
  }
}

# locals {
#   priv_key              = base64decode(var.pri_key)
#   vault_cluster_addr    = data.terraform_remote_state.hcp.outputs.vault_cluster_public_url
#   vault_namespace       = data.terraform_remote_state.hcp.outputs.vault_namespace
#   vault_admin_token     = data.terraform_remote_state.hcp.outputs.vault_admin_token
#   boundary_cluster_addr = data.terraform_remote_state.hcp.outputs.boundary_cluster_url
#   worker_token          = boundary_worker.controller_led.controller_generated_activation_token
#   vault_ca_pub_key      = tls_private_key.signing-key.public_key_openssh
# }



provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"

  azs                     = data.aws_availability_zones.available.names
  cidr                    = var.network_address_space
  enable_dns_hostnames    = true
  #enable_nat_gateway      = true
  #single_nat_gateway      = false
  #one_nat_gateway_per_az  = false
  name                    = "${var.name}-vpc"
  #private_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  private_subnets         = []
  public_subnets          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  #database_subnets        = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}


# ## Access and Security Groups

# resource "aws_security_group" "bastionhost" {
#   name        = "${var.name}-bastionhost-sg"
#   description = "Bastionhosts"
#   vpc_id      = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "jh-ssh" {
#   security_group_id = aws_security_group.bastionhost.id
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "jh-boundary" {
#   security_group_id = aws_security_group.bastionhost.id
#   type              = "ingress"
#   from_port         = 9202
#   to_port           = 9202
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "jh-egress" {
#   security_group_id = aws_security_group.bastionhost.id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group" "web" {
#   name        = "${var.name}-web-sg"
#   description = "private webserver"
#   #vpc_id      = aws_vpc.hashicorp_vpc.id
#   vpc_id = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "web-http" {
#   security_group_id = aws_security_group.web.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "web-https" {
#   security_group_id = aws_security_group.web.id
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "web-ssh" {
#   security_group_id = aws_security_group.web.id
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "web-mysql" {
#   security_group_id = aws_security_group.web.id
#   type              = "ingress"
#   from_port         = 3306
#   to_port           = 3306
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }


# resource "aws_security_group_rule" "web-egress" {
#   security_group_id = aws_security_group.web.id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }


# resource "aws_security_group" "nat" {
#   name        = "${var.name}-nat-sg"
#   description = "nat instance"
#   vpc_id      = module.vpc.vpc_id
# }

# resource "aws_security_group_rule" "nat-http" {
#   security_group_id = aws_security_group.nat.id
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "nat-htts" {
#   security_group_id = aws_security_group.nat.id
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

# resource "aws_security_group_rule" "nat-egress" {
#   security_group_id = aws_security_group.nat.id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

