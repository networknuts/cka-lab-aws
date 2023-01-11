variable "vpc_cidr" {
        default = "10.0.0.0/16"
        description = "cidr for our custom vpc"
}

variable "public_subnet_cidr" {
        default = "10.0.1.0/24"
        description = "cidr for public subnet"
}

variable "private_subnet_cidr" {
        default = "10.0.2.0/24"
        description = "cidr for private subnet"
}

variable "availability_zone" {
        default = "ap-south-1a"
        description = "AZ for subnet"
}

variable "instance_ami" {
        default = "ami-0ef82eeba2c7a0eeb"
        description = "default ami for k8s ubuntu 20.04 LTS"
}

variable "instance_type" {
        default = "t2.medium"
        description = "instance type for k8s ec2"
}

variable "nodetwo_instance_type" {
        default = "t2.small"
        description = "instance type for nodetwo"
}

variable "nodeone_instance_type" {
        default = "t2.micro"
        description = "instance type for nodeone"
}


variable "env_tag" {
        default = "nat-test"
        description = "environment tag"
}
