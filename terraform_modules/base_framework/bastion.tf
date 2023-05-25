data aws_ami ubuntu {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-${var.ubuntu_release}-*-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
  owners      = ["099720109477"] # Canonical
}


resource aws_security_group ssh_icmp_access_to_jump_machine {
  vpc_id = aws_vpc.base_vpc.id

  ingress {
    from_port   = -1
    protocol    = "ICMP"
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22 # SSH
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data cloudinit_config jump_machine {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = yamlencode({
      users = [
        {
          name                = "terraform"
          sudo                = "ALL=(ALL) NOPASSWD:ALL"
          groups              = "users"
          shell               = "/bin/bash"
          homedir             = "/home/terraform"
          lock_passwd         = true
          ssh_authorized_keys = [
            tls_private_key.ssh_client.public_key_openssh,
          ]
          ssh_keys = {
            rsa_public  = tls_private_key.coreint_ca.public_key_pem
            rsa_private = tls_private_key.coreint_ca.private_key_pem
          }
        }
      ]
    })
  }
}


resource aws_instance jump_machine {
  provisioner remote-exec {
    connection {
      type        = "ssh"
      user        = "terraform"
      host        = self.public_ip
      host_key    = tls_private_key.coreint_ca.public_key_openssh
      private_key = tls_private_key.ssh_client.private_key_pem
    }
    inline = ["echo cloud-init finished configuring this host. I am able to connect."]
  }

  tags = {
    accessible_from = "world"
    workload        = "ssh_jump"
    Name            = "${var.canary_name} - Bastion"
  }
  volume_tags = {
    workload = "ssh_jump"
  }

  ami           = data.aws_ami.ubuntu.id
  instance_type = "${var.instance_type}"

  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [
    aws_default_security_group.default.id,
    aws_security_group.ssh_icmp_access_to_jump_machine.id
  ]

  key_name         = aws_key_pair.ssh_key_pair.key_name
  user_data_base64 = data.cloudinit_config.jump_machine.rendered
}


output jump_machine {
  value = {
    aws_instance = {
      jump_machine = {
        public_ip                  = aws_instance.jump_machine.public_ip
        host_key                   = tls_private_key.coreint_ca.public_key_openssh
        public_key_fingerprint_md5 = tls_private_key.coreint_ca.public_key_fingerprint_md5
      }
    }
  }
}
