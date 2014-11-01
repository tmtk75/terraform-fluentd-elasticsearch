variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}
variable "aws_region" {}
variable "cidr_vpc" {
    default = "192.168.11.0/24"
}
variable "cidr_home" {}
variable "ami" {
    default = "ami-c6daff94"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

module "vpc" {
    source = "github.com/tmtk75/terraform-modules//aws/vpc"
    cidr = "${var.cidr_vpc}"
    aws_region = "${var.aws_region}"
}

resource "aws_security_group" "allow_all_from_home" {
    vpc_id = "${module.vpc.vpc_id}"
    name = "allow_all_from_home"
    description = "Allow all inbound traffic from home"
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
}

resource "aws_instance" "jump" {
    ami = "${var.ami}"
    instance_type = "t2.micro"
    subnet_id = "${module.vpc.subnet_id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all_from_home.id}"]
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
    ami = "${var.ami}"
    instance_type = "t2.micro"
    subnet_id = "${module.vpc.subnet_id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all_from_home.id}"]
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
    value = ["${aws_instance.fluentd.*.private_dns}"]
}

resource "aws_instance" "elasticsearch" {
    ami = "${var.ami}"
    instance_type = "t2.micro"
    subnet_id = "${module.vpc.subnet_id}"
    key_name = "${var.key_name}"
    security_groups = ["${aws_security_group.allow_all_from_home.id}"]
    count = 2
}

output "private_dns.elasticsearch" {
    value = ["${aws_instance.elasticsearch.*.private_dns}"]
}

resource "aws_eip" "elasticsearch_0" {
    instance = "${aws_instance.elasticsearch.0.id}"
    vpc = true
}

resource "aws_eip" "elasticsearch_1" {
    instance = "${aws_instance.elasticsearch.1.id}"
    vpc = true
}

output "public_ip.elasticsearch" {
    value = ["${aws_instance.elasticsearch.*.public_ip}"]
}

resource "aws_elb" "elasticsearch" {
    name = "elb-elasticsearch"
    #availability_zones = ["${var.aws_region}a"]
    subnets = ["${module.vpc.subnet_id}"]
    security_groups = ["${aws_security_group.allow_all_from_home.id}"]
    instances = ["${aws_instance.elasticsearch.*.id}"]
    
    listener {
        instance_port = 9200
        instance_protocol = "http"
        lb_port = 9200
        lb_protocol = "http"
    }
    
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 5
        target = "HTTP:9200/"
        interval = 10
    }
}

