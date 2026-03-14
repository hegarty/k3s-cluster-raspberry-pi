# Application Layer Deployment

Deploy services onto the k3s cluster using Helm via Ansible.

## Required Outcome

- MetalLB installed and functional
- Ingress controller installed
- All pods in Running state
- Metrics accessible via curl

## Constraints

- Applications must be installed via Helm
- Helm charts must be stored in /helm
- Ansible may invoke Helm but not embed manifests inline
- No manual kubectl apply
- Must pass all tests in /tests

## Validation

Run:

ansible-playbook playbooks/apps.yml

Then verify:

kubectl get pods -A
kubectl get svc -A

Prometheus must report:

- kube_node_status_condition{condition="Ready"} == 1
- All application pods up
