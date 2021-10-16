data "aws_ami" "jenkins-app"{
    most_recent = true
    # owners = ["amazon"]
    owners = ["099720109477"]

    filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210430"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

data "aws_subnet" "subnet_public" {
    cidr_block = var.subnet_cidr
}

# SSH Key
resource "aws_key_pair" "jenkins-sshkey" {
    key_name = "jenkins-app-key"
    public_key = var.ssh_key
}

resource "aws_instance" "jenkins-app" {
    ami = data.aws_ami.jenkins-app.id
    instance_type = var.app_instance
    subnet_id = data.aws_subnet.subnet_public.id
    associate_public_ip_address = true
    tags = merge(var.app_tags,
            {
            "Name" = format("%s-app", var.app_name)
            },)
    key_name = aws_key_pair.jenkins-sshkey.id
    # bootstrap file
    user_data = file("${path.module}/files/jenkins.sh")

}

resource "aws_security_group" "allow-jenkins" {
    name = format("%s-sg-app", var.app_name)
    description = "allow ssh and http port"
    vpc_id = var.vpc_id
    tags = merge(var.app_tags,{
        "Name" = format("%s-sg-app", var.app_name)
    })
}

resource "aws_security_group_rule" "allow-jenkins-ingress-http" {
    type = "ingress"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-jenkins.id
}

resource "aws_security_group_rule" "allow-jenkins-ingress-ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-jenkins.id
}

resource "aws_security_group_rule" "allow-jenkins-egress-all" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_group_id = aws_security_group.allow-jenkins.id
}

resource "aws_network_interface_sg_attachment" "jenkins" {
    security_group_id = aws_security_group.allow-jenkins.id
    network_interface_id = aws_instance.jenkins-app.primary_network_interface_id
}

resource "aws_route53_zone" "jenkins_zone" {
    name = format("%s-route53-zone-app", var.app_name)
    vpc {
        vpc_id = var.vpc_id
    }
    tags = var.app_tags
}