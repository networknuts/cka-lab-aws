# code - creating vpc

resource "aws_vpc" "vpcone" {
        cidr_block = "${var.vpc_cidr}"
        tags = {
                Name = "${var.env_tag}-vpc"
        }
}

# code - creating IG and attaching it to VPC

resource "aws_internet_gateway" "vpcone-ig" {
        vpc_id = "${aws_vpc.vpcone.id}"
        tags = {
                Name = "${var.env_tag}-IG"
        }
}


# code - public subnet inside our vpc

resource "aws_subnet" "subnet_public" {
        vpc_id = "${aws_vpc.vpcone.id}"
        cidr_block = "${var.public_subnet_cidr}"
        map_public_ip_on_launch = "false"
        availability_zone = "${var.availability_zone}"
        tags = {
                Name = "${var.env_tag}-public"
        }

}

# code - private subnet inside our vpc

resource "aws_subnet" "subnet_private" {
        vpc_id = "${aws_vpc.vpcone.id}"
        cidr_block = "${var.private_subnet_cidr}"
        map_public_ip_on_launch = "false"
        availability_zone = "${var.availability_zone}"
        tags = {
                Name = "${var.env_tag}-private"
        }

}

# code - route table using IG

resource "aws_route_table" "rtb_public" {
        vpc_id = "${aws_vpc.vpcone.id}"
        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.vpcone-ig.id}"
        }
        tags = {
                Name = "${var.env_tag}-public"
        }
}


# code - attaching public subnet to route table using IG

resource "aws_route_table_association" "rta_subnet_public" {
        subnet_id = "${aws_subnet.subnet_public.id}"
        route_table_id = "${aws_route_table.rtb_public.id}"
}

## code - create NAT gateway in public subnet

resource "aws_eip" "nat_gateway" {
  vpc = true
  tags = {
     Name = "${var.env_tag}-nat-ip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.subnet_public.id
  tags = {
    Name = "${var.env_tag}-NG"
  }
}

output "nat_gateway_ip" {
  value = aws_eip.nat_gateway.public_ip
}

## code - creating route table using  NAT for private subnet
resource "aws_route_table" "instance" {
  vpc_id = aws_vpc.vpcone.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "${var.env_tag}-private"
  }
}

## code - attaching NAT route table with private subnet

resource "aws_route_table_association" "instance" {
  subnet_id = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.instance.id
}

##### vpc code finished ####
##### network setup complete ####

# code - create security group

resource "aws_security_group" "sg_newvpc" {
        name = "newvpc"
        vpc_id = "${aws_vpc.vpcone.id}"

        ingress {
#               from_port = 22
                from_port = 0
#               to_port = 22
                to_port = 0
#               protocol = "tcp"
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }

        tags = {
                Name = "${var.env_tag}-SG"
        }

}


# code - create instance in public subnet - manager

resource "aws_instance" "manager" {
        ami = "${var.instance_ami}"
        instance_type = "${var.instance_type}"
        subnet_id = "${aws_subnet.subnet_public.id}"
        vpc_security_group_ids = ["${aws_security_group.sg_newvpc.id}"]
        private_ip = "10.0.1.100"
        key_name = "hpe-cka"
        root_block_device {
          volume_size = "26"
          volume_type = "gp2"
          delete_on_termination = true
        }
        user_data = <<-EOF
          #!/bin/bash
          sudo hostnamectl set-hostname manager
          sudo echo "10.0.1.100 manager" >> /etc/hosts
          echo -e "\n manager - 10.0.1.100 \n nodeone - 10.0.2.101 \n nodetwo - 10.0.2.102 \n" > /root/cluster-ip.txt
        EOF
        tags = {
                Name = "${var.env_tag}-mgr"
        }
}

# code - attaching EIP with manager

resource "aws_eip" "manager-eip" {
  instance = aws_instance.manager.id
  vpc = true
  tags = {
    Name = "${var.env_tag}-mgr"
  }
}

# get public IP on screen after apply

output "manager-eip" {
  description = "Public IP address of the K8S manager"
  value = aws_eip.manager-eip.public_ip
}


# code for nodeone in private subnet

resource "aws_instance" "nodeone" {
        ami = "${var.instance_ami}"
        instance_type = "${var.nodeone_instance_type}"
        subnet_id = "${aws_subnet.subnet_private.id}"
        vpc_security_group_ids = ["${aws_security_group.sg_newvpc.id}"]
        private_ip = "10.0.2.101"
        key_name = "hpe-cka"
        root_block_device {
          volume_size = "26"
          volume_type = "gp2"
          delete_on_termination = true
        }
        user_data = <<-EOF
          #!/bin/bash
          sudo hostnamectl set-hostname nodeone
          sudo echo "10.0.2.101 nodeone" >> /etc/hosts
          echo -e "\n manager - 10.0.1.100 \n nodeone - 10.0.2.101 \n nodetwo - 10.0.2.102 \n" > /root/cluster-ip.txt
        EOF


        tags = {
                Name = "${var.env_tag}-nodeone"
        }
}

# code for nodetwo in private subnet

resource "aws_instance" "nodetwo" {
        ami = "${var.instance_ami}"
        instance_type = "${var.nodetwo_instance_type}"
        subnet_id = "${aws_subnet.subnet_private.id}"
        vpc_security_group_ids = ["${aws_security_group.sg_newvpc.id}"]
        private_ip = "10.0.2.102"
        key_name = "hpe-cka"
        root_block_device {
          volume_size = "26"
          volume_type = "gp2"
          delete_on_termination = true
        }
        user_data = <<-EOF
          #!/bin/bash
          sudo hostnamectl set-hostname nodetwo
          sudo echo "10.0.2.102 nodetwo" >> /etc/hosts
          echo -e "\n manager - 10.0.1.100 \n nodeone - 10.0.2.101 \n nodetwo - 10.0.2.102 \n" > /root/cluster-ip.txt
        EOF


        tags = {
                Name = "${var.env_tag}-nodetwo"
        }
}
