data "template_file" "cloudinit_master_node" {
#  template = file("./templates/userdata.yaml") 
template = file("${path.module}/templates/userdata_m.yaml")
  vars = {

    cloud_type         = "vcloud" #to let ansible know which csi to install

    vcloud_vdc         = var.vcloud_vdc
    vcloud_orgname     = var.vcloud_orgname
    vcloud_user        = var.vcloud_user
    vcloud_password    = var.vcloud_password
    vcloud_csiadmin_username   = var.vcloud_csiadmin_username
    vcloud_csiadmin_password   = var.vcloud_csiadmin_password
    vcloud_url         = var.vcloud_url
    vcloud_catalogname = var.vcloud_catalogname
    vcloud_vmtmplname  = var.vcloud_vmtmplname
    vcloud_orgvnet     = var.vcloud_orgvnet
    vapp_name          = var.vapp_name

    vm_user_name        = var.vm_user_name
    vm_user_password    = var.vm_user_password
    vm_user_displayname = var.vm_user_displayname     
    vm_user_ssh_key     = var.vm_user_ssh_key
    vm_user_ssh_pk      = var.vm_user_ssh_pk

    ansible_repo_url    = var.ansible_repo_url
    ansible_repo_name   = var.ansible_repo_name
    ansible_playbook    = var.ansible_playbook
    
    os_admin_username   = var.os_admin_username
    os_nic1_name        = var.os_nic1_name

    k8s_ver             = var.k8s_ver
    k8s_version_short   = var.k8s_version_short
    calico_version      = var.calico_version
    
    k8s_controlPlane_Endpoint = var.k8s_controlPlane_Endpoint
    k8s_service_subnet  = var.k8s_service_subnet
    k8s_pod_subnet      = var.k8s_pod_subnet
    calico_network_cidr_blocksize = var.calico_network_cidr_blocksize
    k8s_cluster_id      = var.k8s_cluster_id
    sc_storage_policy_name = var.sc_storage_policy_name
    sc_name             = var.sc_name

    ingress_ext_fqdn    = var.ingress_ext_fqdn

    alertmgr_telegram_receiver_name = var.alertmgr_telegram_receiver_name
    alertmgr_telegram_bot_token     = var.alertmgr_telegram_bot_token
    alertmgr_telegram_chatid        = var.alertmgr_telegram_chatid

    hosts_entry1        = "${split("/", var.vms.masters.ip_pool[0])[0]}  ${var.vms.masters.pref}-0"
    hosts_entry2        = "${split("/", var.vms.masters.ip_pool[1])[0]}  ${var.vms.masters.pref}-1"
    hosts_entry3        = "${split("/", var.vms.workers.ip_pool[0])[0]}  ${var.vms.workers.pref}-0"
    hosts_entry4        = "${split("/", var.vms.workers.ip_pool[1])[0]}  ${var.vms.workers.pref}-1"
    hosts_entry5        = "${split("/", var.vms.workers.ip_pool[2])[0]}  ${var.vms.workers.pref}-2"
    
    master0_name        = "${var.vms.masters.pref}-0"
    master0_ip          = "${split("/", var.vms.masters.ip_pool[0])[0]}"
    master1_ip          = "${split("/", var.vms.masters.ip_pool[1])[0]}"
    worker0_ip          = "${split("/", var.vms.workers.ip_pool[0])[0]}" 
    worker1_ip          = "${split("/", var.vms.workers.ip_pool[1])[0]}"
    worker2_ip          = "${split("/", var.vms.workers.ip_pool[2])[0]}"

    masters_count       = var.vms.masters.vm_count
    ansible_ssh_pass    = var.ansible_ssh_pass
  }
}
data "template_file" "cloudinit_worker_node" {
template = file("${path.module}/templates/userdata_w.yaml")
  vars = {

    vm_user_name        = var.vm_user_name
    vm_user_password    = var.vm_user_password
    vm_user_displayname = var.vm_user_displayname     
    vm_user_ssh_key     = var.vm_user_ssh_key
    vm_user_ssh_pk      = var.vm_user_ssh_pk

    ansible_repo_url    = var.ansible_repo_url
    ansible_repo_name   = var.ansible_repo_name
    ansible_playbook    = var.ansible_playbook
    
    os_admin_username   = var.os_admin_username
    os_nic1_name        = var.os_nic1_name

    k8s_ver             = var.k8s_ver
    k8s_version_short   = var.k8s_version_short
    calico_version      = var.calico_version
    #vsphere_csi_driver_version = var.vsphere_csi_driver_version
    k8s_controlPlane_Endpoint = var.k8s_controlPlane_Endpoint
    k8s_service_subnet  = var.k8s_service_subnet
    k8s_pod_subnet      = var.k8s_pod_subnet
    calico_network_cidr_blocksize = var.calico_network_cidr_blocksize
    k8s_cluster_id      = var.k8s_cluster_id
    sc_storage_policy_name = var.sc_storage_policy_name
    sc_name             = var.sc_name
    
    
    hosts_entry1        = "${split("/", var.vms.masters.ip_pool[0])[0]}  ${var.vms.masters.pref}-0"
    hosts_entry2        = "${split("/", var.vms.masters.ip_pool[1])[0]}  ${var.vms.masters.pref}-1"
    hosts_entry3        = "${split("/", var.vms.workers.ip_pool[0])[0]}  ${var.vms.workers.pref}-0"
    hosts_entry4        = "${split("/", var.vms.workers.ip_pool[1])[0]}  ${var.vms.workers.pref}-1"
    hosts_entry5        = "${split("/", var.vms.workers.ip_pool[2])[0]}  ${var.vms.workers.pref}-2"
    
    master0_ip          =  "${split("/", var.vms.masters.ip_pool[0])[0]}"
    master1_ip          =  "${split("/", var.vms.masters.ip_pool[1])[0]}"
    worker0_ip          =  "${split("/", var.vms.workers.ip_pool[0])[0]}" 
    worker1_ip          =  "${split("/", var.vms.workers.ip_pool[1])[0]}"
    worker2_ip          =  "${split("/", var.vms.workers.ip_pool[2])[0]}"
  }
}

data "vcd_catalog" "vcd_dp_linux" {
    org  = var.vcloud_orgname
    name = var.vcloud_catalogname

}