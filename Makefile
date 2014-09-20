#
#
#
var_path=~/.aws/default.tfvars
opts=-var-file $(var_path)
tfcmd=./bin/terraform

plan:
	$(tfcmd) plan $(opts)

apply:
	$(tfcmd) apply $(opts)

refresh:
	$(tfcmd) refresh $(opts)

show:
	$(tfcmd) show terraform.tfstate

ensure-vpc:
	aws ec2 modify-vpc-attribute --vpc-id `terraform output vpc_id` --enable-dns-hostnames '{"Value":true}'

ssh-config:
	./ssh-config.sh > ssh-config

vars.yml:
	$(tfcmd) show terraform.tfstate | ./vars.py > vars.yml

uptime: ssh-config
	ansible all -i ./hosts -m command -a uptime

setup: ssh-config
	ansible all -i ./hosts -m setup

members:
	ansible all -i ./hosts -l jump -m command -a "consul members"

playbook: ssh-config vars.yml
	ansible-playbook -i ./hosts playbook.yaml -f 4

post-fluentd:
	curl -v -XPOST http://`$(tfcmd) output public_ip.fluentd`:8888/es.test -d 'json={"a":1}'

#
# WORKAROUND: elasticsearch sometimes cannot be in a cluster if two nodes launch at same time.
#
restart-es:
	ansible `$(tfcmd) output private_dns.elasticsearch|sed 's/,.*//g'` \
	  -i./hosts -m command -s \
	  -a "service elasticsearch restart"

#
# Destroy & cleanup
#
plan-destroy:
	$(tfcmd) plan -destroy -out destroy.tfplan $(opts)

destroy: plan-destroy
	$(tfcmd) apply destroy.tfplan

clean:
	rm -f ssh-config vars.yml

distclean: clean
	rm -f terraform.tfstate* destroy.tfplan

#
#
#
ssh-fluentd: ssh-config
	ssh -F ssh-config `$(tfcmd) output private_dns.fluentd`

ssh-es: ssh-config
	ssh -F ssh-config `$(tfcmd) output private_dns.elasticsearch|sed 's/,.*//g'`

#
#
#
install-es-head:
	ansible elasticsearch -i./hosts \
	  -m command -s \
	  -a "/usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head"

open-es-head:
	open http://`$(tfcmd) output public_ip.elasticsearch|sed 's/,.*//g'`:9200/_plugin/head
#
#
#
galaxy: roles/tmtk75.consul roles/tmtk75.serf roles/tmtk75.dnsmasq roles/tmtk75.elasticsearch roles/tmtk75.td-agent

roles/tmtk75.consul:
	ansible-galaxy install tmtk75.consul -p roles

roles/tmtk75.serf:
	ansible-galaxy install tmtk75.serf -p roles

roles/tmtk75.dnsmasq:
	ansible-galaxy install tmtk75.dnsmasq -p roles

roles/tmtk75.elasticsearch:
	ansible-galaxy install tmtk75.elasticsearch -p roles

roles/tmtk75.td-agent:
	ansible-galaxy install tmtk75.td-agent -p roles

#
#
#
terraform: bin/terraform

bin/terraform: bin/terraform_0.2.0_darwin_amd64.zip
	(cd bin; unzip terraform_0.2.0_darwin_amd64.zip)

bin/terraform_0.2.0_darwin_amd64.zip:
	(mkdir -p bin; cd bin; curl -OL https://dl.bintray.com/mitchellh/terraform/terraform_0.2.0_darwin_amd64.zip)

#
#
#
ansible: .e/bin/ansible

.e/bin/ansible: .e
	.e/bin/pip2.7 install ansible

.e/bin/aws: .e
	.e/bin/pip2.7 install awscli

.e:
	virtualenv .e
