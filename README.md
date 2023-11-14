# Hetzner-k3s-bootstrap
Initial setup
```
hcloud context create project <id>
task helm-repo-add 
```
Personal repo for bootstrapping my single-node k3s cluster on Hetzner-Cloud.

```
task tf-init
task tf-apply
task init-cluster
task update-ip
```
To monitor cluster with k9s (this uses the `k3s_kubeconfig.yaml` file as the `KUBECONFIG` environ - created by `terraform-kube-hetzner` in `task tf-apply` ):
```
task k9s
```
To tear down:

```
tak tf-destroy
```

# Internals

The project does the following:

1. Deploy a 1-server-k3s-cluster by using [terraform-hcloud-kube-hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner)
1. Install the cluster-addons/helm charts
1. Use my small Go toolset to update the HetznerDNS records of my personal domain to point to the new endpoint of the created server [hetzner-tools-go](https://github.com/jdvgh/hetzner-tools-go)
