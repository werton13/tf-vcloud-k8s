variable "project" {
  type = object({
    owner_org = string
    name      = string
    env_name  = string
  })
  description = "Here we define project information to simplify and organize objects naming"
}

variable "vcloud" {
  type = object({
    server_fqdn           = string
    server_ip             = string
    allow_unverified_ssl  = optional(string, "true")
    max_retry_timeout     = optional(string, "240")
    vdc                   = string
    orgname               = string
    admin                 = string
    admin_pwd             = string
    csi_svc               = string
    csi_svc_pwd           = string
    vapp_name             = string # shared vApp for k8s nodes (required by vCloud CSI)
    catalogname           = string
    catalog_org           = optional(string, "") # Organization owning the catalog (defaults to vcloud.orgname)
    vm_template_name      = string
    orgvnet_name          = string
    edgegw                = string
    env_type              = optional(string, "public")
    network_type          = optional(string, "nsx-v") # "nsx-v" (Edge LB + NAT) or "nsx-t" (kube-vip VIPs + Edge NAT)
    public_ip             = optional(string, "")      # NSX-V only: optional public IP override (auto-detected from Edge Gateway if empty). NSX-T uses kubernetes.vip.public_ip
    external_network_name = optional(string, "")      # NSX-V only: optional external network override (auto-detected from Edge Gateway if empty)
    lbvm_count            = optional(string, "0")
  })
  description = "VMware Cloud Director connection and environment configuration"

  validation {
    condition     = contains(["nsx-v", "nsx-t"], var.vcloud.network_type)
    error_message = "vcloud.network_type must be \"nsx-v\" or \"nsx-t\"."
  }
}

variable "ip_plan" {
  type = object({
    m_node     = string
    w_node     = string
    dvm        = string
    kubeapi_lb = string
    ingress_lb = string
  })
  default = {
    m_node     = "4"  # first master node IP will be x.x.x.4
    w_node     = "7"  # first worker node IP will be x.x.x.7
    dvm        = "-3" # DVM IP will be -3 from the end of subnet - i.e. 192.168.0.253 for 192.168.0.0/24
    kubeapi_lb = "2"  # KubeAPI LB VIP (e.g. x.x.x.2)
    ingress_lb = "3"  # Ingress LB VIP (e.g. x.x.x.3)
  }
  description = "Here we define IP address distribution for VMs and virtual services from the network CIDR"
}

variable "vms_config" {
  type = map(object({
    vm_cpu_count = string
    vm_ram_size  = string
    vm_disk_size = optional(string, "20")
    vm_count     = string
  }))
  description = "Virtual machine sizing and counts for master, worker, and dvm nodes"
}

variable "os_config" {
  type = object({
    vm_user_name        = string
    vm_user_password    = string
    ansible_ssh_pass    = string
    vm_user_displayname = string
    vm_user_ssh_key     = optional(string, "")
    vm_ip_cidr          = string
    def_dns             = string
    env_dns1            = string
    env_dns2            = string
    env_dns3            = optional(string, "")
    ntp_srv1            = optional(string, "")
    ntp_srv2            = optional(string, "")
    ubuntu_animal_code  = optional(string, "noble") # noble for Ubuntu 24.04, jammy for 22.04
    docker_mirror       = optional(string, "")
    os_nic1_name        = string
  })
  description = "Operating system configuration, credentials and network settings"
}

variable "disks_config" {
  type = map(object({
    sizegb          = string
    bus_num         = string
    unit_num        = string
    storage_profile = string
    bus_type        = string
  }))
  default = {
    osdisk = {
      sizegb          = "20"
      bus_num         = "0"
      unit_num        = "0"
      storage_profile = ""
      bus_type        = "paravirtual"
    }
    diskm1 = {
      sizegb          = "10"
      bus_num         = "1"
      unit_num        = "0"
      storage_profile = ""
      bus_type        = "paravirtual"
    }
    diskm2 = {
      sizegb          = "30"
      bus_num         = "1"
      unit_num        = "1"
      storage_profile = ""
      bus_type        = "paravirtual"
    }
    diskw1 = {
      sizegb          = "10"
      bus_num         = "1"
      unit_num        = "0"
      storage_profile = ""
      bus_type        = "paravirtual"
    }
    diskw2 = {
      sizegb          = "30"
      bus_num         = "1"
      unit_num        = "1"
      storage_profile = ""
      bus_type        = "paravirtual"
    }
  }
  description = "Storage configuration for OS disks and data disks attached to nodes"
}

variable "ansible" {
  type = object({
    git_repo = object({
      repo_url      = optional(string, "https://github.com/werton13/k8s-kubeadm-r2.git")
      repo_name     = optional(string, "k8s-kubeadm-r2")
      repo_branch   = optional(string, "dev")
      playbook_name = optional(string, "main.yaml")
    })
    vault_secret = optional(string, "vault_k8s_super_secret_password")
  })
  default = {
    git_repo = {
      repo_url      = "https://github.com/werton13/k8s-kubeadm-r2.git"
      repo_name     = "k8s-kubeadm-r2"
      repo_branch   = "dev"
      playbook_name = "main.yaml"
    }
    vault_secret = "vault_k8s_super_secret_password"
  }
  description = "Ansible repository configuration and vault secret for encrypting inventory credentials"
}

variable "node_controller" {
  type = object({
    enabled                              = optional(bool, false)
    acknowledge_terraform_ownership_loss = optional(bool, false)
    namespace                            = optional(string, "vcd-nodescale-system")
    release_name                         = optional(string, "vcd-nodescale")
    chart_repo                           = optional(string, "https://werton13.github.io/vcd-k8s-node-controller")
    chart_name                           = optional(string, "vcd-nodescale")
    chart_version                        = optional(string, "0.1.5")
    image_repository                     = optional(string, "docker.io/werton13/vcd-k8s-node-controller")
    image_tag                            = optional(string, "0.1.5")
    image_pull_policy                    = optional(string, "IfNotPresent")
    create_namespace                     = optional(bool, true)
    create_vcd_secret                    = optional(bool, true)
    vcd_secret_name                      = optional(string, "vcd-credentials")
    vcd_user                             = optional(string, "")
    vcd_password                         = optional(string, "")
    vcd_insecure                         = optional(bool, true)
    helm_timeout                         = optional(string, "10m")
    helm_atomic                          = optional(bool, true)
    create_pool                          = optional(bool, true)
  })
  default     = {}
  description = <<-EOT
    Optional vcd-k8s-node-controller (worker autoscaling) configuration.

    All settings have defaults. When enabling the controller, the only values a
    project normally must provide are:
      - acknowledge_terraform_ownership_loss = true
      - vcd_user / vcd_password (a dedicated vCD service account)

    WARNING: enabling this controller transfers ownership of worker scaling and
    worker LB pool membership from Terraform to the controller/CRD. After it is
    enabled, Terraform must not be used to manage the cluster (no further apply
    for worker count, node configuration, or LB membership).
  EOT

  validation {
    condition     = !var.node_controller.enabled || var.node_controller.acknowledge_terraform_ownership_loss
    error_message = "Enabling node_controller requires acknowledge_terraform_ownership_loss = true. Terraform will no longer own worker scaling or worker LB pool membership."
  }

  validation {
    condition = !var.node_controller.enabled || (
      var.node_controller.namespace != "" &&
      var.node_controller.release_name != "" &&
      var.node_controller.chart_repo != "" &&
      var.node_controller.chart_name != "" &&
      var.node_controller.chart_version != "" &&
      var.node_controller.image_repository != "" &&
      var.node_controller.image_tag != ""
    )
    error_message = "When node_controller.enabled = true, namespace, release_name, chart_repo, chart_name, chart_version, image_repository and image_tag must be set."
  }
}

variable "kubernetes" {
  type = object({
    cluster = object({
      version = string
    })
    cni = object({
      svc_subnet                    = string
      pod_subnet                    = string
      calico_network_cidr_blocksize = string
    })
    pvc = object({
      sc_storage_policy_name = string
      sc_name                = string
    })
    ingress = object({
      controller_nodeport_http  = string
      controller_nodeport_https = string
      ext_fqdn                  = optional(string, "")
    })
    vip = optional(object({
      public_ip                = optional(string, "")        # NSX-T only: public Edge Gateway IP (required for network_type = "nsx-t")
      public_port_kubeapi      = optional(string, "6443")    # NSX-T: public port DNAT'ed to the KubeAPI VIP:6443
      public_port_ingress_http = optional(string, "80")      # NSX-T: public port DNAT'ed to the ingress VIP:80
      public_port_dvm_ssh      = optional(string, "")        # NSX-T: public port DNAT'ed to DVM:22 (empty = no rule)
      kube_vip_enabled         = optional(bool, true)        # NSX-T: kube-vip owns the KubeAPI and ingress VIPs
      kube_vip_version         = optional(string, "v0.8.10") # kube-vip image tag
      kube_vip_address         = optional(string, "")        # Computed as ip_plan.kubeapi_lb / k8s_controlPlane_Endpoint; optional override must match
      ingress_lb_ip            = optional(string, "")        # Computed as ip_plan.ingress_lb; optional override must match
      k8s_api_extra_sans       = optional(list(string), [])  # Additional API server SANs; public_ip is appended automatically
    }), {})
  })
  description = "Kubernetes cluster configuration parameters"
}

variable "versions" {
  type        = any
  description = "Version matrix for Kubernetes releases and addon components"
}

variable "obs_config" {
  type = object({
    common = object({
      obs_type = string # vm_stack / prom_stack / none
    })
    vm_stack = optional(object({
      type                  = optional(string, "operator")
      remoteWriteUrl        = optional(string, "")
      remoteWriteUsername   = optional(string, "")
      remoteWritePassword   = optional(string, "")
      etcdProxyMainImageURL = optional(string, "")
      etcdProxyInitImageURL = optional(string, "")
      label_env_name        = optional(string, "")
      label_dctr_name       = optional(string, "")
      label_project_name    = optional(string, "")
    }), {})
    prom_stack = optional(object({
      prometheus = optional(object({
        param1 = optional(string, "")
      }), {})
      alertmanager = optional(object({
        telegram_receiver_name = optional(string, "")
        telegram_bot_token     = optional(string, "")
        telegram_chatid        = optional(string, "")
      }), {})
      grafana = optional(object({
        param1 = optional(string, "")
      }), {})
    }), {})
  })
  default = {
    common = {
      obs_type = "vm_stack"
    }
    vm_stack   = {}
    prom_stack = {}
  }
  description = "Observability and monitoring configuration"
}
