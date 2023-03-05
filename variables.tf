
# vcloud variables -----------------------
variable vcloud_url {
  type        = string
  default     = ""
  description = "vcloud director url"
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
# vApp configuration variables --------------------------------
variable vcd_vapp_net_gw {
  type        = string
  default     = "10.10.13.1"
  description = "vApp network default gateway IP"
}
variable vcd_vapp_net_mask {
  type        = string
  default     = "255.255.255.0"
  description = "vApp network mask - like 255.255.255.0"
}
variable vcd_vapp_net_dns1 {
  type        = string
  default     = "8.8.8.8"
  description = "DNS1 for vApp network"
}
variable vcd_vapp_net_dns2 {
  type        = string
  default     = "1.1.1.1"
  description = "DNS2 for vApp network"
}
variable static_ip_pool_start {
  type        = string
  default     = "10.10.13.100"
  description = "first IP in the vApp network static pool"
}
variable static_ip_pool_end {
  type        = string
  default     = "10.10.13.200"
  description = "last IP in the vApp network static pool"
}

# fw rule1
variable fw_rule1_name {
  type        = string
  default     = ""
  description = "firewall rule name for vAp network"
}
variable fw_rule1_action {
  type        = string
  default     = "allow"
  description = "firewall rule policy action -allow/deny"
}
variable fw_rule1_proto {
  type        = string
  default     = ""
  description = "firewall rule protocol - TCP/UDP"
}
variable fw_rule1_src_ip {
  type        = string
  default     = ""
  description = "firewall rule source IP"
}
variable fw_rule1_src_port {
  type        = string
  default     = ""
  description = "firewall rule source port"
}
variable fw_rule1_dst_ip {
  type        = string
  default     = ""
  description = "firewall rule destination IP"
}
variable fw_rule1_dst_port {
  type        = string
  default     = ""
  description = "firewall rule destination port"
}
# fw rule2
variable fw_rule2_name {
  type        = string
  default     = ""
  description = "firewall rule name for vAp network"
}
variable fw_rule2_action {
  type        = string
  default     = "allow"
  description = "firewall rule policy action -allow/deny"
}
variable fw_rule2_proto {
  type        = string
  default     = ""
  description = "firewall rule protocol - TCP/UDP"
}
variable fw_rule2_src_ip {
  type        = string
  default     = ""
  description = "firewall rule source IP"
}
variable fw_rule2_src_port {
  type        = string
  default     = ""
  description = "firewall rule source port"
}
variable fw_rule2_dst_ip {
  type        = string
  default     = ""
  description = "firewall rule destination IP"
}
variable fw_rule2_dst_port {
  type        = string
  default     = ""
  description = "firewall rule destination port"
}
# fw rule3
variable fw_rule3_name {
  type        = string
  default     = ""
  description = "firewall rule name for vAp network"
}
variable fw_rule3_action {
  type        = string
  default     = "allow"
  description = "firewall rule policy action -allow/deny"
}
variable fw_rule3_proto {
  type        = string
  default     = ""
  description = "firewall rule protocol - TCP/UDP"
}
variable fw_rule3_src_ip {
  type        = string
  default     = ""
  description = "firewall rule source IP"
}
variable fw_rule3_src_port {
  type        = string
  default     = ""
  description = "firewall rule source port"
}
variable fw_rule3_dst_ip {
  type        = string
  default     = ""
  description = "firewall rule destination IP"
}
variable fw_rule3_dst_port {
  type        = string
  default     = ""
  description = "firewall rule destination port"
}

# variable to define quantity and size of K8s nodes
variable "vms" {
    description: "variable to define quantity and size of K8s nodes, please check readme for example"
    type = map(object({
        pref = string
        vm_cpu_count = string
        vm_ram_size  = string
        vm_disk_size = string
        vm_count = string
        ip_pool = list(string)
    }))
  
    default = {
      masters = {
        pref = "k8s-m"
        vm_cpu_count = "2"
        vm_ram_size  = "4096"
        vm_disk_size = "40"
        vm_count = "1"
        ip_pool =  ["10.10.13.110",
                    "10.10.13.111"]
      },
      workers = {
        pref = "k8s-w"
        vm_cpu_count = "4"
        vm_ram_size  = "8192"
        vm_disk_size = "40"
        vm_count = "3"
        ip_pool =  ["10.10.13.114",
                    "10.10.13.115",
                    "10.10.13.116"]
      
      }
}

 }

############ for Ansible playbook
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
#variable "vsphere_csi_driver_version" {
#  type        = string
#  default     = ""
#  description = "description"
# }
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





















