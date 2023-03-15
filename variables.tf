
# vcloud variables -----------------------
variable vcloud_url {
  type        = string
  default     = ""
  description = "vcloud director url"
 }

variable vcloud_ip {
  type        = string
  default     = ""
  description = "description"
}

variable vcloud_allow_unverified_ssl {
  type        = string
  description = "vCD allow unverified SSL"
  default     = "true"
 }

variable "vcloud_max_retry_timeout" {
  description = "Retry Timeout"
  default     = "240"
 }
variable vcloud_vdc {
  type        = string
  default     = ""
  description = "vCloud VDC name"
 }
variable vcloud_orgname {
  type        = string
  default     = ""
  description = "vCloud tenant name"
 }
variable vcloud_user {
  type        = string
  default     = ""
  description = "vCloud tenant admin username"
 }
variable vcloud_password {
  type        = string
  default     = ""
  description = "vCloud tenant admin password"
 }

variable vcloud_csiadmin_username {
  type        = string
  default     = ""
  description = "dedicated vcloud user account for creating named disks"
}
variable vcloud_csiadmin_password {
  type        = string
  default     = ""
  description = "dedicated vcloud user account password for creating named disks"
}

variable vapp_name {
  type        = string
  default     = ""
  description = "vcloud vapp name for placing all K8s VMs and network components"
}
variable vcloud_catalogname {
  type        = string
  default     = ""
  description = "vcloud catalog, there is vm Linux template located"
}
variable vcloud_vmtmplname  {
  type        = string
  default     = ""
  description = "Linux template prepared from Ubuntu cloud image, prepared for disk.UUIDEnabled option and placed to vcloud catalogue"
}

variable vcloud_orgvnet {
  type        = string
  default     = ""
  description = "Name of vcloud org-level virtual network which will binded to vApp vnet"
}

#vm configuration variables--------------------------------
variable "vm_user_name" {
   type        = string
   default     = ""
   description = "user name for a new vm user"
 }
variable "vm_user_password" {
  type        = string
  default     = ""
  description = "vm user password - should be SHA-512 hash of desired password"
 }

variable "vm_user_displayname" {
   type        = string
   default     = ""
   description = "user  display name for a new vm user"
 }

variable "vm_user_ssh_key" {
   type        = string
   default     = ""
   description = "user ssh key for a new vm user"
 }


# variable to define quantity and size of K8s nodes
variable "vms" {
    description = "variable to define quantity and size of K8s nodes, please check readme for example"
    type = map(object({
        pref = string
        vm_cpu_count = string
        vm_ram_size  = string
        vm_disk_size = string
        vm_count = string
        ip_pool = list(string)
    }))
  
  #  default = {
  #    masters = {
  #      pref = "k8s-m"
  #      vm_cpu_count = "2"
  #      vm_ram_size  = "4096"
  #      vm_disk_size = "40"
  #      vm_count = "1"
  #      ip_pool =  ["192.168.100.110",
  #                  "192.168.100.111",
  #                  "192.168.100.112"]
  #    },
  #    workers = {
  #      pref = "k8s-w"
  #      vm_cpu_count = "4"
  #      vm_ram_size  = "8192"
  #      vm_disk_size = "40"
  #      vm_count = "3"
  #      ip_pool =  ["192.168.100.114",
  #                  "192.168.100.115",
  #                  "192.168.100.116"]
  #    
  #    }
  #}

 }

############ variables for Ansible playbook
variable "ansible_repo_url" {
   type        = string
   default     = "https://github.com/werton13/k8s-kubeadm-ansible.git"
   description = "ansible playbook URL for bootstrap K8s cluster, writed specifically for this project"
 }
variable "ansible_repo_name"  {
  type        = string
  default     = "k8s-kubeadm-ansible"
  description = "ansible git repository name for bootstrap K8s cluster, writed specifically for this project"
 }
variable ansible_repo_branch {
  type        = string
  default     = "main"
  description = "description"
}

variable "ansible_playbook" {
   type        = string
   default     = "main.yaml"
   description = "ansible playbook name for for bootstrap K8s cluster, writed specifically for this project"
 }
variable "os_admin_username" {
  type        = string
  default     = "kuberadm"
  description = "username for nodes OS admin account"
 }
variable "os_nic1_name" {
  type        = string
  default     = ""
  description = "default nick id created in ubuntu 20.04/22.04"
 }
variable ansible_ssh_pass {
  type        = string
  default     = ""
  description = "password value for creating ansible inventory - should be in clear text"
 }



############# Versions of components

variable "k8s_ver" {
  type        = string
  default     = "1.22.17-00"
  description = "Kubernetes release version, default 1.22 to be inline with vCloud CSI driver support list"
 }
variable "k8s_version_short" {
  type        = string
  default     = "1.22.0"
  description = "Kubernetes release version - shortened"
 }
variable "calico_version" {
  type        = string
  default     = "v3.25.0"
  description = "Calico CNI version"
 }

variable "k8s_controlPlane_Endpoint" {
  type        = string
  default     = ""
  description = "IP of K8s LB or first K8s IP - for the test deployments"
 }
variable "k8s_service_subnet" {
  type        = string
  default     = "10.96.0.0/12"
  description = "Kubernetes services internal subnet"
 }
variable "k8s_pod_subnet" {
  type        = string
  default     = "10.244.0.0/22"
  description = "Kubernetes POD's network"
 }
variable "calico_network_cidr_blocksize" {
  type        = string
  default     = "26"
  description = "Calico CNI CIDR block size"
 }
variable "k8s_cluster_id" {
  type        = string
  default     = ""
  description = "The unique cluster identifier. using in CSI driver config"
 }
variable "sc_storage_policy_name" {
  type        = string
  default     = ""
  description = "vCloud storage policy"
 }
variable "sc_name" {
  type        = string
  default     = ""
  description = "default Kubernetes storage class name"
 }
variable vm_user_ssh_pk {
  type        = string
  default     = "none"
  description = "SSH "
}
variable ingress_ext_fqdn {
  type        = string
  default     = ""
  description = "FQDN to build general prefix for the K8s Ingress controller endpoint's, published to outside"
}

# sensitive variables for Alert manager telegram integration
variable alertmgr_telegram_receiver_name {
  type        = string
  default     = ""
  description = "alert manager receiver name for a Telegram receiver"
}
variable alertmgr_telegram_bot_token {
  type        = string
  default     = ""
  description = "telegram bot token for alertmanager integration"
}
variable alertmgr_telegram_chatid {
  type        = string
  default     = ""
  description = "telegram chat_id for alertmanager integration"
}
### test block ###########################################
#variable worker0_name  {
#  type        = string
#  default     = ""
#  description = "description"
#}
#variable workers_count {
#  type        = string
#  default     = ""
#  description = "description"
#}
#variable test_array {
#  type        = list(string)
#  default     = []
#  description = "description"
#}

























