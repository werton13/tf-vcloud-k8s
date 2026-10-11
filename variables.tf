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
    server_fqdn              = string
    server_ip                = string
    allow_unverified_ssl     = optional(string, "true")
    max_retry_timeout        = optional(string, "240")
    vdc                      = string
    orgname                  = string
    admin                    = string
    admin_pwd                = string
    csi_svc                  = string
    csi_svc_pwd              = string
    vapp_name                = string
    catalogname              = string
    vm_template_name         = string
    orgvnet_name             = string
    edgegw                   = string
    env_type                 = optional(string, "public")
    network_type             = optional(string, "nsx-v") # "nsx-v" or "nsx-t"
    alb_service_engine_group = optional(string, "")      # required when network_type = "nsx-t" (Avi ALB Service Engine Group name)
    lbvm_count               = optional(string, "0")
  })
  description = "VMware Cloud Director connection and environment configuration"
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
    vm_user_ssh_key     = string
    vm_ip_cidr          = string
    def_dns             = string
    env_dns1            = string
    env_dns2            = string
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
      repo_branch   = optional(string, "dev-r3")
      playbook_name = optional(string, "main.yaml")
    })
    vault_secret = optional(string, "vault_k8s_super_secret_password")
  })
  default = {
    git_repo = {
      repo_url      = "https://github.com/werton13/k8s-kubeadm-r2.git"
      repo_name     = "k8s-kubeadm-r2"
      repo_branch   = "dev-r3"
      playbook_name = "main.yaml"
    }
    vault_secret = "vault_k8s_super_secret_password"
  }
  description = "Ansible repository configuration and vault secret for encrypting inventory credentials"
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
