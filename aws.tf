variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}
variable "aws_region" {}
variable "cidr" {
    default = "192.168.11.0/24"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_vpc" "my-vpc" {
    cidr_block = "${var.cidr}"
    enable_dns_support = true
    enable_dns_hostnames = true
}

output "vpc_id" {
    value = "${aws_vpc.my-vpc.id}"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    cidr_block = "${var.cidr}"
    availability_zone = "${var.aws_region}c"
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.my-vpc.id}"
}

resource "aws_route_table" "igw" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    route {
        gateway_id = "${aws_internet_gateway.gw.id}"
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_route_table_association" "main_and_igw" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.igw.id}"
}

#
# Handling security groups by terraform is buggy yet
# It doesn't work properly for multiple security groups as my expectation
#
resource "aws_security_group" "allow_all" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    name = "allow_all"
    description = "Allow all inbound traffic"
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "jump" {
    ami = "ami-29dc9228"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.main.id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all.id}"]
    count = 1
}

output "private_dns.jump " {
    value = "${aws_instance.jump.private_dns}"
}

resource "aws_eip" "jump" {
    instance = "${aws_instance.jump.id}"
    vpc = true
}

output "public_ip.jump" {
    value = "${aws_instance.jump.public_ip}"
}

resource "aws_instance" "fluentd" {
    ami = "ami-29dc9228"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.main.id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all.id}"]
    count = 1
}

resource "aws_eip" "fluentd" {
    instance = "${aws_instance.fluentd.id}"
    vpc = true
}

output "public_ip.fluentd" {
    value = "${aws_instance.fluentd.public_ip}"
}

output "private_dns.fluentd" {
    value = "${aws_instance.fluentd.*.private_dns}"
}

resource "aws_instance" "elasticsearch" {
    ami = "ami-29dc9228"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.main.id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all.id}"]
    count = 2
}

output "private_dns.elasticsearch" {
    value = "${aws_instance.elasticsearch.*.private_dns}"
}

resource "aws_eip" "elasticsearch.0" {
    instance = "${aws_instance.elasticsearch.0.id}"
    vpc = true
}

resource "aws_eip" "elasticsearch.1" {
    instance = "${aws_instance.elasticsearch.1.id}"
    vpc = true
}

output "public_ip.elasticsearch" {
    value = "${aws_instance.elasticsearch.*.public_ip}"
}

#
# aws_elb doesn't support VPC yet...?
#
#resource "aws_elb" "elasticsearch" {
#  name = "elb-elasticsearch"
#  availability_zones = ["${aws_instance.elasticsearch.*.availability_zone}"]
#  listener {
#    instance_port = 9200
#    instance_protocol = "http"
#    lb_port = 9200
#    lb_protocol = "http"
#  }
#  instances = ["${aws_instance.elasticsearch.*.id}"]
#}

