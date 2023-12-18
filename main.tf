data "terraform_remote_state" "hcp" {
  backend = "remote"

  config = {
    organization = var.tfc_state_org
    workspaces = {
      name = var.rs_platform_hcp
    }
  }
}


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

