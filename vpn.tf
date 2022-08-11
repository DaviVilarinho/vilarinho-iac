resource "aws_instance" "vpn" {
  ami                         = "ami-0022f774911c1d690"
  key_name                    = aws_key_pair.vpn.key_name
  instance_type               = "t3.nano"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.vpn.name]
  user_data = templatefile("assets/vpn.tpl", {
    AWS_BACKUP_BUCKET = aws_s3_bucket.shared_backups.id
  })
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.vpn_instance.id
}

resource "aws_security_group" "vpn" {

  name        = "vpn-security-group"
  description = "Allowing http traffic and ssh"

  ingress {
    description      = "SSH to host"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH to vpn repos"
    from_port        = 2222
    to_port          = 2222
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_iam_policy_document" "vpn_role_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vpn_s3" {
  statement {
    sid     = "S3ACCESSBUCKETS"
    effect  = "Allow"
    actions = ["s3:*", "s3api:*"]
    resources = [
      aws_s3_bucket.shared_backups.arn,
      "${aws_s3_bucket.shared_backups.arn}/*"
    ]
  }
  statement {
    sid    = "S3LIST"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::*"]
  }
}

resource "aws_iam_role" "vpn" {
  name_prefix        = "vpn-instance-role"
  path               = "/automation/vpn/"
  assume_role_policy = data.aws_iam_policy_document.vpn_role_assume_role.json
  inline_policy {
    name   = "vpn_S3_ACCESS"
    policy = data.aws_iam_policy_document.vpn_s3.json
  }
}

resource "aws_iam_instance_profile" "vpn_instance" {
  name = "vpn-instance-instance-profile"
  role = aws_iam_role.vpn.id
}

resource "tls_private_key" "vpn_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn" {
  key_name   = "vpn-instance-key"
  public_key = tls_private_key.vpn_key.public_key_openssh
}

data "aws_route53_zone" "website" {
  name = "vilarinho.click."
}

resource "aws_route53_record" "vpn" {
  zone_id = data.aws_route53_zone.website.zone_id
  name    = "vpn.vilarinho.click"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.vpn.public_ip]
}
