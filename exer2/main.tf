module "jenkinsapp" {
    source = "./modules/jenkins-app"
    vpc_id = "YOUR_VPC_ID"
    subnet_cidr = "YOUR_SUBNET_IP_RANGE"
    ssh_key = "public_key"
    app_name = "jenkins"
    app_tags ={
        env = "prod"
        project = "jenkins"
        customer = "impacta"
    }
    app_instance = "t3.small"
}

resource "null_resource" "getJenkinsPwd" {
    triggers = {
        instance = module.jenkinsapp.jenkins-app
    }
    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file("${path.module}/modules/jenkins-app/files/slacko")
        host = module.jenkinsapp.jenkins-app
    }
    provisioner "remote-exec" {
    inline = [
        "sleep 300",
        "sudo cat /var/lib/jenkins/secrets/initialAdminPassword",
    ]
  }
}

output "jenkins-ip" {
    value = module.jenkinsapp.jenkins-app
}
