locals {
  # You have the choice of setting your Hetzner API token here or define the TF_VAR_hcloud_token env
  # within your shell, such as such: export TF_VAR_hcloud_token=xxxxxxxxxxx
  # If you choose to define it in the shell, this can be left as is.

  # Your Hetzner token can be found in your Project > Security > API Token (Read & Write is required).
  hcloud_token = ""
}
data "hcloud_ssh_key" "ssh_key_hetzner" {
  fingerprint = var.ssh_key_hetzner_fingerprint
}
module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  version      = "2.11.8"
  hcloud_token = var.hcloud_token != "" ? var.hcloud_token : local.hcloud_token
  extra_firewall_rules = [
      {
        description     = "Allow Outbound SSH Requests"
        direction       = "out"
        protocol        = "tcp"
        port            = "22"
        destination_ips = ["0.0.0.0/0", "::/0"]
      },
  ]
  # Then fill or edit the below values. Only the first values starting with a * are obligatory; the rest can remain with their default values, or you
  # could adapt them to your needs.

  # For normal use, this is the path to the terraform registry
  source = "kube-hetzner/kube-hetzner/hcloud"

  # * Your ssh public key
  ssh_public_key = file(var.ssh_public_key_file_path)
  # * Your private key must be "ssh_private_key = null" when you want to use ssh-agent for a Yubikey-like device authentification or an SSH key-pair with a passphrase.
  # For more details on SSH see https://github.com/kube-hetzner/kube-hetzner/blob/master/docs/ssh.md
  ssh_private_key = file(var.ssh_private_key_file_path)

  # If you want to use an ssh key that is already registered within hetzner cloud, you can pass its id.
  # If no id is passed, a new ssh key will be registered within hetzner cloud.
  # It is important that exactly this key is passed via `ssh_public_key` & `ssh_private_key` variables.
  hcloud_ssh_key_id = data.hcloud_ssh_key.ssh_key_hetzner.id

  # These can be customized, or left with the default values
  # * For Hetzner locations see https://docs.hetzner.com/general/others/data-centers-and-connection/
  network_region = "eu-central" # change to `us-east` if location is ash

  # For the control planes, at least three nodes are the minimum for HA. Otherwise, you need to turn off the automatic upgrades (see README).
  # **It must always be an ODD number, never even!** Search the internet for "splitbrain problem with etcd" or see https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/
  # For instance, one is ok (non-HA), two is not ok, and three is ok (becomes HA). It does not matter if they are in the same nodepool or not! So they can be in different locations and of various types.

  # Of course, you can choose any number of nodepools you want, with the location you want. The only constraint on the location is that you need to stay in the same network region, Europe, or the US.
  # For the server type, the minimum instance supported is cpx11 (just a few cents more than cx11); see https://www.hetzner.com/cloud.

  # IMPORTANT: Before you create your cluster, you can do anything you want with the nodepools, but you need at least one of each, control plane and agent.
  # Once the cluster is up and running, you can change nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1).
  # You can also rename it (if the count is 0), but do not remove a nodepool from the list.

  # You can safely add or remove nodepools at the end of each list. That is due to how subnets and IPs get allocated (FILO).
  # The maximum number of nodepools you can create combined for both lists is 50 (see above).
  # Also, before decreasing the count of any nodepools to 0, it's essential to drain and cordon the nodes in question. Otherwise, it will leave your cluster in a bad state.

  # Before initializing the cluster, you can change all parameters and add or remove any nodepools. You need at least one nodepool of each kind, control plane, and agent.
  # The nodepool names are entirely arbitrary, you can choose whatever you want, but no special characters or underscore, and they must be unique; only alphanumeric characters and dashes are allowed.

  # If you want to have a single node cluster, have one control plane nodepools with a count of 1, and one agent nodepool with a count of 0.

  # Please note that changing labels and taints after the first run will have no effect. If needed, you can do that through Kubernetes directly.

  # ⚠️ When choosing ARM cax* server types, for the moment they are only available in fsn1.
  # Muli-architecture clusters are OK for most use cases, as container underlying images tend to be multi-architecture too.

  # * Example below:

  control_plane_nodepools = [
    {
      name        = "control-plane-fsn1",
      server_type = "cpx21",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 1
      # swap_size   = "2G" # remember to add the suffix, examples: 512M, 1G
      # zram_size   = "2G" # remember to add the suffix, examples: 512M, 1G
      # kubelet_args = ["kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=1Gi", "system-reserved=cpu=memory=200Mi"]



      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    {
      name        = "control-plane-nbg1",
      server_type = "cpx11",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 0

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    {
      name        = "control-plane-hel1",
      server_type = "cpx11",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 0

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-small",
      server_type = "cpx11",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 0
      # swap_size   = "2G" # remember to add the suffix, examples: 512M, 1G
      # zram_size   = "2G" # remember to add the suffix, examples: 512M, 1G
      # kubelet_args = ["kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=1Gi", "system-reserved=cpu=memory=200Mi"]



      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    {
      name        = "agent-large",
      server_type = "cpx21",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 0

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    {
      name        = "storage",
      server_type = "cpx21",
      location    = "fsn1",
      # Fully optional, just a demo.
      labels = [
        "node.kubernetes.io/server-usage=storage"
      ],
      taints = [],
      count  = 0

      # In the case of using Longhorn, you can use Hetzner volumes instead of using the node's own storage by specifying a value from 10 to 10000 (in GB)
      # It will create one volume per node in the nodepool, and configure Longhorn to use them.
      # Something worth noting is that Volume storage is slower than node storage, which is achieved by not mentioning longhorn_volume_size or setting it to 0.
      # So for something like DBs, you definitely want node storage, for other things like backups, volume storage is fine, and cheaper.
      # longhorn_volume_size = 20

      # Enable automatic backups via Hetzner (default: false)
      # backups = true
    },
    # Egress nodepool useful to route egress traffic using Hetzner Floating IPs (https://docs.hetzner.com/cloud/floating-ips)
    # used with Cilium's Egress Gateway feature https://docs.cilium.io/en/stable/gettingstarted/egress-gateway/
    # See the https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner#examples for an example use case.
    {
      name        = "egress",
      server_type = "cpx11",
      location    = "fsn1",
      labels = [
        "node.kubernetes.io/role=egress"
      ],
      taints = [
        "node.kubernetes.io/role=egress:NoSchedule"
      ],
      floating_ip = true
      count       = 0
    },
    # Arm based nodes, currently available only in FSN location
    {
      name        = "agent-arm-small",
      server_type = "cax11",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 0
    }
  ]
  # * LB location and type, the latter will depend on how much load you want it to handle, see https://www.hetzner.com/cloud/load-balancer
  load_balancer_type     = "lb11"
  load_balancer_location = "fsn1"
  # Disable IPv6 for the load balancer, the default is false.
  load_balancer_disable_ipv6 = false

  # If you want to disable the automatic upgrade of k3s, you can set below to "false".
  # Ideally, keep it on, to always have the latest Kubernetes version, but lock the initial_k3s_channel to a kube major version,
  # of your choice, like v1.25 or v1.26. That way you get the best of both worlds without the breaking changes risk.
  # For production use, always use an HA setup with at least 3 control-plane nodes and 2 agents, and keep this on for maximum security.

  # The default is "true" (in HA setup i.e. at least 3 control plane nodes & 2 agents, just keep it enabled since it works flawlessly).
  automatically_upgrade_k3s = false

  # The default is "true" (in HA setup it works wonderfully well, with automatic roll-back to the previous snapshot in case of an issue).
  # IMPORTANT! For non-HA clusters i.e. when the number of control-plane nodes is < 3, you have to turn it off.
  automatically_upgrade_os = false
  # Traefik, all Traefik helm values can be found at https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
  # The following is an example, please note that the current indentation inside the EOT is important.

  traefik_values = <<EOT
ingressRoute:
  dashboard:
    # -- Create an IngressRoute for the dashboard
    enabled: false
    EOT
}

provider "hcloud" {
  token = var.hcloud_token != "" ? var.hcloud_token : local.hcloud_token
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.43.0"
    }
  }
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}

variable "hcloud_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "ssh_key_hetzner_fingerprint" {
  type      = string
  sensitive = true
}
variable "ssh_public_key_file_path" {
  type      = string
  sensitive = true
}

variable "ssh_private_key_file_path" {
  type      = string
  sensitive = true
}
