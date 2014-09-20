# README

# Overviwe

Demo for Terraform & Ansible

```
            +----> elasticsearch
            |
fluentd ----+
            |
            +----> elasticsearch


           ^
           |    login w/ private DNS like ip-192-168-11-16.ap-northeast-1.compute.internal
          jump
```

- consul runs at all hosts in the same cluster
- serf runs at all hosts in the same cluster


# Getting Started
## Prerequesties
- virtualenv
- make
- AWS access keys
- Private key name

Create a file as `~/.aws/default.tfvars`.

```
aws_access_key = <your aws access key>
aws_secret_key = <your aws access secret>
key_name = <your private key name>
aws_region = ap-northeast-1
```

## Setup

```
$ make terraform ansible
$ source .env
```

```
$ make apply ensure-vpc
```

Wait for outputs has all values like (you can check `make apply`)

```
Outputs:

  private_dns.elasticsearch = ip-192-168-11-252.ap-northeast-1.compute.internal,ip-192-168-11-16.ap-northeast-1.compute.internal
  private_dns.fluentd       = ip-192-168-11-96.ap-northeast-1.compute.internal
  private_dns.jump          = ip-192-168-11-228.ap-northeast-1.compute.internal
  public_ip.elasticsearch   = 54.64.17.175,54.64.17.174
  public_ip.fluentd         = 54.64.7.118
  public_ip.jump            = 54.64.17.176
  vpc_id                    = vpc-24709941
```

```
$ make ssh-config vars.yml
```

Two files, `ssh-config` and `vars.yml` are generated. `ssh-config` has settings to login w/ ssh via jump host.

```
$ ssh -F ssh-config jump
...
[ec2-user@ip-192-168-11-228 ~]$
```

```
$ ssh -F ssh-config ip-192-168-11-252.ap-northeast-1.compute.internal
...
[ec2-user@ip-192-168-11-252 ~]$
```

Wait for EC2 instances have launched. You can check `make uptime`.
If all instances are ready, you can kick `make playbook`.

```
$ make playbook
```
