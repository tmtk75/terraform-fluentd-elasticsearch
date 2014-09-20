#!/usr/bin/env bash
ip=$(terraform output public_ip.jump)
cat<<EOH
Host *
  StrictHostKeyChecking=no
  UserKnownHostsFile=/dev/null
  LogLevel ERROR

Host jump
  HostName $ip
  User ec2-user

Host *.ap-northeast-1.compute.internal
  ProxyCommand ssh -l ec2-user -W %h:%p $ip
  User ec2-user
EOH
