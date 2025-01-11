#vCloud variables
vcloud_vdc      = "My-VDC"
vcloud_orgname  = "My_orgname"
vcloud_user     = "My_vcloud_username"
vcloud_password = "My_vcloud_password"
vcloud_csiadmin_username = "vcloud_username_for_csi"
vcloud_csiadmin_password = "vcloud_password_for_csi" # do not use specials like $,',\ - it could be

vcloud_url      = "https://my_vcloud_web_portal_url/api"
vcloud_ip       = "my_vcloud_web_portal IP address"
vcloud_catalogname = "my_vcloud_catalogue_name"
vcloud_vmtmplname  = "ubuntu22.04-uuid-enabled-v1"
vcloud_orgvnet     = "my_vcloud_org_vnet_name"
vcloud_edgegw      = "my_vcloud_edgegw"


vapp_name = "my_vapp_name"

vm_user_name  = "kuberadm"
vm_user_displayname = "kunernetes cluster admin"
vm_user_password = "$6$rounds=----."                 # mkpasswd  --method=SHA-512 --rounds=4096 somesecretpassword
vm_user_ssh_key = "ssh-ed25519 somessh pub key here" # ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "john@example.com" '


vms = {
    masters = {
      pref = "k8s-m"
      vm_cpu_count = "2"
      vm_ram_size  = "4096"
      vm_disk_size = "40"
      vm_count = "1"
      ip_pool =  ["192.168.100.110",
                  "192.168.100.111"]
    },
    workers = {
      pref = "k8s-w"
      vm_cpu_count = "4"
      vm_ram_size  = "8192"
      vm_disk_size = "40"
      vm_count = "3"
      ip_pool =  ["192.168.100.114",
                  "192.168.100.115",
                  "192.168.100.116"]
    }
}

#System disk vars
system_disk_bus = "paravirtual"
system_disk_size =  "20"
#system_disk_storage_profile =

#############  additional disks #############
  add_disks = {
          disk1 = {
            sizegb = "10"
            bus_num = "1"
            unit_num = "0"
            storage_profile = ""
            bus_type = "paravirtual" 
          }
          disk2 = {
            sizegb = "30"
            bus_num = "1"
            unit_num = "1"
            storage_profile = ""
            bus_type = "paravirtual"  
          }
}

############# DNS config ##############
def_dns  = "8.8.8.8"     # default dns configured in the base image
env_dns1 = "10.10.6.6"   # desired DNS1 server IP address, specifical to the target environment
env_dns2 = "10.11.7.7"   # desired DNS1 server IP address, specifical to the target environment

############# K8s Networking parameters
k8s_cluster_name = "k8s-lab"
k8s_controlPlane_Endpoint = "192.168.100.200"
ingress_lb_ip = "192.168.100.210"
k8s_service_subnet = "10.96.0.0/12"
k8s_pod_subnet = "10.244.0.0/22"
calico_network_cidr_blocksize = "26"

############# OS config parameters
os_admin_username = "kuberadm"
os_nic1_name = "ens192"
ansible_ssh_pass = "somesecretpasswordhere"


############# Ansible Ccnfiguration #############
ansible_repo_url  = "https://github.com/werton13/k8s-kubeadm-r2.git"
ansible_repo_name =  "k8s-kubeadm-r2"
ansible_repo_branch = "dev" #"main"
ansible_playbook = "main.yaml"

############# Versions of components #############
docker_mirror      = "mirror.gcr.io"
k8s_ver = "1.28.6-1.1"
k8s_version_short = "1.28.6"
calico_version = "v3.27.2"
vsphere_csi_driver_version = "v2.7.0"
helm_version = "v3.11.1"

# vCloud CSI vars
sc_storage_policy_name = "my_vcloud_stotage_policy_name"
sc_name = "my storage_classname_desired" # for vcloud

############# Ingress config #############
ingress_ext_fqdn = "myenvironment.fqdn"
ingress_controller_nodeport_http = "30888"
ingress_controller_nodeport_https = "30443"

############# Monitoring config #############
alertmgr_telegram_receiver_name = "test-telegram"
alertmgr_telegram_bot_token = "mytelegram_bot_secret_token"
alertmgr_telegram_chatid = "-mytelegramchatid"
# Go to this address and talk to BotFather to get a new bot.
#  https://core.telegram.org/bots#6-botfather
#
# Take note of the Token
# Create a channel and invite the bot to the channel
#
# The bot must be invited as admin.
# Find the chat ID:
#  after the bot is in the channel, type a message in the channel, then go to:
#  https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates


############# K8s RBAC paramaters
tenant_cluster_ro_rolename = "tenant-cluster-readonly"
tenant_ns_default = "mts-ehealth-default"
tenant_k8s_admin_username = "tenant-admin"
tenant_orgname = "tenant-orgname"
tenant_orgname_orgunit = "tenant-orgname-k8s"
tenant_emailaddress = "tenant-admin@tenant-orgname.lab"
certificate_validity = "180"  #30/60 or 180 и.т.д.

######################################################################