module "vpc" {
 source = "terraform-aws-modules/vpc/aws"
 name = "main_vpc"
 cidr = "10.0.0.0/16"
 azs             = ["us-east-1a", "us-east-1c"]
 public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
 enable_nat_gateway = false
 single_nat_gateway  = false
 enable_vpn_gateway = false
 one_nat_gateway_per_az = false
 enable_dns_hostnames = true
 create_egress_only_igw = true
 tags = { }
}

variable "resource_tags" {
   type = map(string)
   default = {}
}

locals {
 required_tags = {
     "project" = "impacta",
     "environment" = "prod"
 } 
 tags = merge(var.resource_tags, local.required_tags)
}
