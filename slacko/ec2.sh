#! /bin/bash
yum update
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user
docker run --restart always --network=host leonardodg2084/skacko-api:1.0.0
