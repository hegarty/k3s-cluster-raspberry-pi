ANSIBLE_PLAYBOOK := ansible-playbook
INVENTORY        := inventory/hosts.yml
SSH_TARGET       := rpi-1

.PHONY: k3s-install k3s-start k3s-stop kubeconfig-sync

## Install k3s on the edge node (bootstrap OS then install k3s server)
k3s-install:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/bootstrap.yml
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/k3s_server.yml

## Start k3s service on the edge node
k3s-start:
	ssh $(SSH_TARGET) "sudo systemctl start k3s"

## Stop k3s service on the edge node
k3s-stop:
	ssh $(SSH_TARGET) "sudo systemctl stop k3s"

## Pull kubeconfig from the edge node and merge into local ~/.kube/config
KUBE_SERVER      := pi-1.local

kubeconfig-sync:
	scp $(SSH_TARGET):/etc/rancher/k3s/k3s.yaml /tmp/k3s.yaml
	@sed -i '' 's/127.0.0.1/$(KUBE_SERVER)/g' /tmp/k3s.yaml
	KUBECONFIG=~/.kube/config:/tmp/k3s.yaml kubectl config view --flatten > /tmp/merged.yaml
	mv /tmp/merged.yaml ~/.kube/config
	@echo "kubeconfig synced: context set to k3s cluster at $(SSH_TARGET)"

## Deploy application layer (MetalLB, Ingress, Observability)
apps-deploy:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/apps.yml
