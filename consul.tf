locals {
  consul_cluster_addr    = data.terraform_remote_state.hcp.outputs.consul_url
  consul_datacenter      = data.terraform_remote_state.hcp.outputs.consul_datacenter
  consul_root_token      = data.terraform_remote_state.hcp.outputs.consul_root_token
  hvn                    = data.terraform_remote_state.hcp.outputs.hvn
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

resource "aws_security_group" "my_asg" {
  name        = "my_asg"
  description = "Allow my inbound traffic"
  #vpc_id      = data.aws_vpc.selected.id
  vpc_id      = module.vpc.vpc_id
}

# resource "aws_security_group_rule" "egress" {
#   security_group_id = aws_security_group.my_asg.id
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   ipv6_cidr_blocks  = ["::/0"]  
# }

# resource "aws_security_group_rule" "consul-api" {
#   #count             = var.consul_enabled ? 1 : 0
#   security_group_id = aws_security_group.my_asg.id
#   type              = "ingress"
#   from_port         = 8500
#   to_port           = 8503
#   protocol          = "tcp"
#   cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]  
#   #cidr_blocks       = [var.whitelist_ip]
# }

# resource "aws_security_group_rule" "consul-dns-tcp" {
#   #count             = var.consul_enabled ? 1 : 0
#   security_group_id = aws_security_group.my_asg.id
#   type              = "ingress"
#   from_port         = 8600
#   to_port           = 8600
#   protocol          = "tcp"
#   cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
# }

# resource "aws_security_group_rule" "consul-dns-udp" {
#   #count             = var.consul_enabled ? 1 : 0
#   security_group_id = aws_security_group.my_asg.id
#   type              = "ingress"
#   from_port         = 8600
#   to_port           = 8600
#   protocol          = "udp"
#   cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
# }

# resource "aws_security_group_rule" "consul-sidecar" {
#   #count             = var.consul_enabled ? 1 : 0
#   security_group_id = aws_security_group.my_asg.id
#   type              = "ingress"
#   from_port         = 21000
#   to_port           = 21255
#   protocol          = "tcp"
#   cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
# }


// Consul client instance
resource "aws_instance" "consul_client_web" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.my_asg.id,
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
      consul_svc_name  = "webservice"
      consul_svc_id    = "webservice-${count.index + 1}"
      consul_service   = base64encode(templatefile("${path.module}/scripts/service", {
        service_name   = "consul",
        service_cmd    = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      vpc_cidr = var.network_address_space
    })),
  })

  tags = {
    Name = "webservice-${count.index}"
  }
}

resource "aws_instance" "consul_client_db" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.my_asg.id,
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
      consul_svc_name  = "dbservice"
      consul_svc_id    = "dbservice-${count.index + 1}"
      consul_service   = base64encode(templatefile("${path.module}/scripts/service", {
        service_name   = "consul",
        service_cmd    = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      vpc_cidr = var.network_address_space
    })),
  })

  tags = {
    Name = "dbservice-${count.index}"
  }
}