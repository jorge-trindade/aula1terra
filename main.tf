data "aws_ami" "slacko-app"  {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amazon*"]
    }
    
    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

data "aws_vpc" "main_vpc" {
  filter {
    name = "tag:Name"
    values = ["main_vpc"]
  } 
}

data "aws_subnet" "subnet_public" {
    cidr_block = "10.0.102.0/24"
    availability_zone = "us-east-1c"
}

resource "aws_key_pair" "slacko-sshkey"{
    key_name = "slacko-app-key"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZ8QG8cGntLWKFUZCPB01/s8m9JdN0OJ7k4J7IHefR6wHAnBTQkRVVBNYmisWYwYr4RCI/JkigUs0hPYHH/hEb6sY4dXUdFg8bQOSw41FKBqV70cmIJuMeXVdC1///kS1gwkbHuY9+Bgw6ZDhbg/qOSgmbO5T1d+ZYBFGcZVtEPSHj6IjsR5LKGnNMLRMEzlNDGENFIjKJF51aUNli1oYsrHlLZS1RTxgdqy7eo0o37xGq9KUbQ5lNTuKSH9bkBBBspVknDiC2Tpz6yuimjDYbvBhbEbXwJKsJyWkG4x6qtBsABkUiU+5Buoa678W2Dea/dWf9B4YqrJB3Mv/S9ntB1rD3HuwvBCZ9s2rEXyLrKzFpzOIN7AFnzN0A3Ai/+eLAKpNJRaikB0GEer3juuW4MIC6QbX/kEKzzP+vpRT1QoP4qdSws+EeTPG1YHDx0BmYb6IJND10S178+EPJFoD1tsJQFCxSrn0fKbahbc9+5WePDfCmeq0fEI7Lcvah0ss= slacko"
}

resource "aws_instance" "slacko-app" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id
    associate_public_ip_address = true

    tags = {
        Name = "slacko-app"
    }

    key_name = aws_key_pair.slacko-sshkey.id
    # arquivo de bootstrap
    user_data = file("ec2.sh")
}

resource "aws_instance" "mongodb" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id

    tags = {
        Name = "mongodb"
    }

    key_name = aws_key_pair.slacko-sshkey.id
    user_data = file("mongodb.sh")
}    

resource "aws_security_group" "allow-slacko" {
    name = "allow_ssh_http"
    description = "allow ssh and http port"
    vpc_id = data.aws_vpc.main_vpc.id

    ingress = [
        {
        description = "allow SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = []
        security_groups = []
    },   
    {
        description = "allow http"
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = []
        security_groups = []
    }
    ]

    egress = [
        {
        description = "allow all outbound"
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = []
        security_groups = []
        }
    ]

    tags = {
        Name = "allow_ssh_http"
    }
}

resource "aws_security_group" "allow-mongodb" {
    name = "allow_mongodb"
    description = "allow Mongodb"
    vpc_id = data.aws_vpc.main_vpc.id

    ingress = [
        {
        description = "allow mongodb"
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = []
        security_groups = []
        }
    ]

    egress = [
        {
        description = "allow all"
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = []
        security_groups = []
        }
    ]
    
    tags = {
        Name = "allow_mongodb"
    }
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
    security_group_id = aws_security_group.allow-mongodb.id
    network_interface_id = aws_instance.mongodb.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "slacko-sg" {
    security_group_id = aws_security_group.allow-slacko.id
    network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

resource "aws_route53_zone" "slack_zone"{
    name = "iaac0506.com.br"

    vpc {
        vpc_id = data.aws_vpc.main_vpc.id
    }
}

resource "aws_route53_record" "mongodb"{
    zone_id = aws_route53_zone.slack_zone.id
    name = "mongodb.iaac0506.com.br"
    type = "A"
    ttl = "300"
    records = [aws_instance.mongodb.private_ip]
}
