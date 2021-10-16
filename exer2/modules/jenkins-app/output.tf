output "jenkins-app" {
    value = aws_instance.jenkins-app.public_ip
}