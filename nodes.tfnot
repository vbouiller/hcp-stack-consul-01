data "template_file" "worker" {
    template = (join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/worker.sh")
  ])))
  vars = {
    priv_key              = local.priv_key
    boundary_cluster_addr = local.boundary_cluster_addr
    worker_token          = local.worker_token
  }
}

data "template_cloudinit_config" "worker" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.worker.rendered
  }
}


data "template_file" "db_nodes" {
    template = (join("\n", tolist([
    file("${path.root}/templates/base.sh"),
    file("${path.root}/templates/db-nodes.sh")
  ])))
  vars = {
    vault_ca_pub_key  = local.vault_ca_pub_key
    mysql_user        = var.mysql_user
    mysql_password    = var.mysql_password
  }
}

data "template_cloudinit_config" "db_nodes" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.db_nodes.rendered
  }
}


# INSTANCES

resource "aws_instance" "bastionhost" {
  lifecycle {
    ignore_changes = [ user_data ]
  }
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = element(module.vpc.public_subnets, 0)
  #private_ip                  = cidrhost(aws_subnet.dmz_subnet.cidr_block, 10)
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.bastionhost.id]
  key_name                    = var.pub_key
  user_data                   = data.template_cloudinit_config.worker.rendered

  tags = {
    Name = "bastionhost-${var.name}"
  }
}

resource "aws_instance" "web_nodes" {
  count                       = var.web_node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(module.vpc.private_subnets, count.index)

  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.pub_key
  
  tags = {
    Name = format("web-%02d", count.index + 1)
  }
}

## next use case dynamic ssh via vault

resource "aws_instance" "db_nodes" {
  count                       = var.db_node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = element(module.vpc.database_subnets, count.index) 
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.pub_key
  user_data                   = data.template_cloudinit_config.db_nodes.rendered
  
  tags = {
    Name = format("db-%02d", count.index + 1)
  }
}
