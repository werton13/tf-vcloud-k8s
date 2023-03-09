#vCloud variables
vcloud_vdc      = "My-VDC"
vcloud_orgname  = "My_orgname"
vcloud_user     = "My_vcloud_username"
vcloud_password = "My_vcloud_password"
vcloud_url      = "https://my_vcloud_web_portal_url/api"
vcloud_catalogname = "my_vcloud_catalogue_name"
vcloud_vmtmplname  = "ubuntu22.04-uuid-enabled-v1"
vcloud_orgvnet     = "my_vcloud_org_vnet_name"


vapp_name = "my_vapp_name"

vm_user_name  = "kuberadm"
vm_user_displayname = "kunernetes cluster admin"
vm_user_password = "$6$rounds=----."
vm_user_ssh_key = "ssh-ed25519 somessh pub key here"


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


os_admin_username = "kuberadm"
os_nic1_name = "ens192"
ansible_ssh_pass = "somesecretpasswordhere"

############# Versions of components

k8s_ver = "1.22.17-00"

k8s_version_short = "1.22.0"

calico_version = "v3.25.0"

vsphere_csi_driver_version = "v2.7.0"

############# K8s Networking parameters

k8s_controlPlane_Endpoint = "192.168.100.110"
k8s_service_subnet = "10.96.0.0/12"
k8s_pod_subnet = "10.244.0.0/22"
calico_network_cidr_blocksize = "26"

# vCloud CSI vars

sc_storage_policy_name = "my_vcloud_stotage_policy_name"
sc_name = "my storage_classname_desired" # for vcloud

ingress_ext_fqdn = "myenvironment.fqdn"

alertmgr_telegram_receiver_name = "test-telegram"
alertmgr_telegram_bot_token = "mytelegram_bot_secret_token"
alertmgr_telegram_chatid = "-mytelegramchatid"
