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
    ansible_repo_branch = var.ansible_repo_branch
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
    
    #vcloud_fqdn        = "${substr(var.vcloud_url, 8, -4}"
    #vcloud_ip          = var.vcloud_ip

    hosts_entry0        = "${var.vcloud_ip}  ${split("/", var.vcloud_url)[2]}"
    hosts_entry1        = "${split("/", var.vms.masters.ip_pool[0])[0]}  ${var.vms.masters.pref}-0"
    hosts_entry2        = "${split("/", var.vms.masters.ip_pool[1])[0]}  ${var.vms.masters.pref}-1"
    hosts_entry3        = "${split("/", var.vms.masters.ip_pool[2])[0]}  ${var.vms.masters.pref}-2"

    hosts_entry4        = "${split("/", var.vms.workers.ip_pool[0])[0]}  ${var.vms.workers.pref}-0"
    hosts_entry5        = "${split("/", var.vms.workers.ip_pool[1])[0]}  ${var.vms.workers.pref}-1"
    hosts_entry6        = "${split("/", var.vms.workers.ip_pool[2])[0]}  ${var.vms.workers.pref}-2"
    hosts_entry7        = "${split("/", var.vms.workers.ip_pool[3])[0]}  ${var.vms.workers.pref}-3"
    hosts_entry8        = "${split("/", var.vms.workers.ip_pool[4])[0]}  ${var.vms.workers.pref}-4"
    hosts_entry9        = "${split("/", var.vms.workers.ip_pool[5])[0]}  ${var.vms.workers.pref}-5"
    hosts_entry10       = "${split("/", var.vms.workers.ip_pool[6])[0]}  ${var.vms.workers.pref}-6"
    hosts_entry11       = "${split("/", var.vms.dvm.ip_pool[0])[0]}  ${var.vms.dvm.pref}"
    
    master0_name        = "${var.vms.masters.pref}-0"
    worker0_name        = "${var.vms.workers.pref}-0"
       
    master0_ip          = "${split("/", var.vms.masters.ip_pool[0])[0]}"
    master1_ip          = "${split("/", var.vms.masters.ip_pool[1])[0]}"
    master2_ip          = "${split("/", var.vms.masters.ip_pool[2])[0]}"

    worker0_ip          = "${split("/", var.vms.workers.ip_pool[0])[0]}" 
    worker1_ip          = "${split("/", var.vms.workers.ip_pool[1])[0]}"
    worker2_ip          = "${split("/", var.vms.workers.ip_pool[2])[0]}"
    worker3_ip          = "${split("/", var.vms.workers.ip_pool[3])[0]}" 
    worker4_ip          = "${split("/", var.vms.workers.ip_pool[4])[0]}"
    worker5_ip          = "${split("/", var.vms.workers.ip_pool[5])[0]}"
    worker6_ip          = "${split("/", var.vms.workers.ip_pool[6])[0]}" 

    workers_count       = var.vms.workers.vm_count
    masters_count       = var.vms.masters.vm_count
    ansible_ssh_pass    = var.ansible_ssh_pass
    
    tenant_cluster_ro_rolename = var.tenant_cluster_ro_rolename
    tenant_ns_default          = var.tenant_ns_default
    tenant_k8s_admin_username  = var.tenant_k8s_admin_username
    tenant_orgname             = var.tenant_orgname
    tenant_orgname_orgunit     = var.tenant_orgname_orgunit
    tenant_emailaddress        = var.tenant_emailaddress
    certificate_validity       = var.certificate_validity
   


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
    
    
    hosts_entry0        = "${var.vcloud_ip}  ${split("/", var.vcloud_url)[2]}"
    hosts_entry1        = "${split("/", var.vms.masters.ip_pool[0])[0]}  ${var.vms.masters.pref}-0"
    hosts_entry2        = "${split("/", var.vms.masters.ip_pool[1])[0]}  ${var.vms.masters.pref}-1"
    hosts_entry3        = "${split("/", var.vms.masters.ip_pool[2])[0]}  ${var.vms.masters.pref}-2"

    hosts_entry4        = "${split("/", var.vms.workers.ip_pool[0])[0]}  ${var.vms.workers.pref}-0"
    hosts_entry5        = "${split("/", var.vms.workers.ip_pool[1])[0]}  ${var.vms.workers.pref}-1"
    hosts_entry6        = "${split("/", var.vms.workers.ip_pool[2])[0]}  ${var.vms.workers.pref}-2"
    hosts_entry7        = "${split("/", var.vms.workers.ip_pool[3])[0]}  ${var.vms.workers.pref}-3"
    hosts_entry8        = "${split("/", var.vms.workers.ip_pool[4])[0]}  ${var.vms.workers.pref}-4"
    hosts_entry9        = "${split("/", var.vms.workers.ip_pool[5])[0]}  ${var.vms.workers.pref}-5"
    hosts_entry10       = "${split("/", var.vms.workers.ip_pool[6])[0]}  ${var.vms.workers.pref}-6"
    hosts_entry11       = "${split("/", var.vms.dvm.ip_pool[0])[0]}  ${var.vms.dvm.pref}"
    
    master0_ip          =  "${split("/", var.vms.masters.ip_pool[0])[0]}"
    master1_ip          =  "${split("/", var.vms.masters.ip_pool[1])[0]}"
    worker0_ip          =  "${split("/", var.vms.workers.ip_pool[0])[0]}" 
    worker1_ip          =  "${split("/", var.vms.workers.ip_pool[1])[0]}"
    worker2_ip          =  "${split("/", var.vms.workers.ip_pool[2])[0]}"
  }
}

data "template_file" "cloudinit_dvm" {
#  template = file("./templates/userdata.yaml") 
template = file("${path.module}/templates/userdata_dvm.yaml")
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
    ansible_repo_branch = var.ansible_repo_branch
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
    
    #vcloud_fqdn        = "${substr(var.vcloud_url, 8, -4}"
    #vcloud_ip          = var.vcloud_ip

    hosts_entry0        = "${var.vcloud_ip}  ${split("/", var.vcloud_url)[2]}"
    hosts_entry1        = "${split("/", var.vms.masters.ip_pool[0])[0]}  ${var.vms.masters.pref}-0"
    hosts_entry2        = "${split("/", var.vms.masters.ip_pool[1])[0]}  ${var.vms.masters.pref}-1"
    hosts_entry3        = "${split("/", var.vms.masters.ip_pool[2])[0]}  ${var.vms.masters.pref}-2"

    hosts_entry4        = "${split("/", var.vms.workers.ip_pool[0])[0]}  ${var.vms.workers.pref}-0"
    hosts_entry5        = "${split("/", var.vms.workers.ip_pool[1])[0]}  ${var.vms.workers.pref}-1"
    hosts_entry6        = "${split("/", var.vms.workers.ip_pool[2])[0]}  ${var.vms.workers.pref}-2"
    hosts_entry7        = "${split("/", var.vms.workers.ip_pool[3])[0]}  ${var.vms.workers.pref}-3"
    hosts_entry8        = "${split("/", var.vms.workers.ip_pool[4])[0]}  ${var.vms.workers.pref}-4"
    hosts_entry9        = "${split("/", var.vms.workers.ip_pool[5])[0]}  ${var.vms.workers.pref}-5"
    hosts_entry10       = "${split("/", var.vms.workers.ip_pool[6])[0]}  ${var.vms.workers.pref}-6"
    hosts_entry11       = "${split("/", var.vms.dvm.ip_pool[0])[0]}  ${var.vms.dvm.pref}"
    
    
    dvm_name            = "${var.vms.dvm.pref}"
    master0_name        = "${var.vms.masters.pref}-0"
    master1_name        = "${var.vms.masters.pref}-1"
    master2_name        = "${var.vms.masters.pref}-2"

    worker0_name        = "${var.vms.workers.pref}-0"
    worker1_name        = "${var.vms.workers.pref}-1"
    worker2_name        = "${var.vms.workers.pref}-2"
    worker3_name        = "${var.vms.workers.pref}-3"
    worker4_name        = "${var.vms.workers.pref}-4"
    worker5_name        = "${var.vms.workers.pref}-5"
    worker6_name        = "${var.vms.workers.pref}-6"
    
       
    master0_ip          = "${split("/", var.vms.masters.ip_pool[0])[0]}"
    master1_ip          = "${split("/", var.vms.masters.ip_pool[1])[0]}"
    master2_ip          = "${split("/", var.vms.masters.ip_pool[2])[0]}"

    worker0_ip          = "${split("/", var.vms.workers.ip_pool[0])[0]}" 
    worker1_ip          = "${split("/", var.vms.workers.ip_pool[1])[0]}"
    worker2_ip          = "${split("/", var.vms.workers.ip_pool[2])[0]}"
    worker3_ip          = "${split("/", var.vms.workers.ip_pool[3])[0]}" 
    worker4_ip          = "${split("/", var.vms.workers.ip_pool[4])[0]}"
    worker5_ip          = "${split("/", var.vms.workers.ip_pool[5])[0]}"
    worker6_ip          = "${split("/", var.vms.workers.ip_pool[6])[0]}" 

    workers_count       = var.vms.workers.vm_count
    masters_count       = var.vms.masters.vm_count
    ansible_ssh_pass    = var.ansible_ssh_pass
    
    tenant_cluster_ro_rolename = var.tenant_cluster_ro_rolename
    tenant_ns_default          = var.tenant_ns_default
    tenant_k8s_admin_username  = var.tenant_k8s_admin_username
    tenant_orgname             = var.tenant_orgname
    tenant_orgname_orgunit     = var.tenant_orgname_orgunit
    tenant_emailaddress        = var.tenant_emailaddress
    certificate_validity       = var.certificate_validity
   


  }
}

data "vcd_catalog" "vcd_dp_linux" {
    org  = var.vcloud_orgname
    name = var.vcloud_catalogname

}

# monitor_id = data.vcd_lb_service_monitor.kube_api.id
data "vcd_lb_service_monitor" "kube_api" {
    org          = var.vcloud_orgname
    vdc          = var.vcloud_vdc
    edge_gateway = var.vcloud_edgegw
    name         = "kube_api"

}

#data "template_file" "test_node" {
##  template = file("./templates/userdata.yaml") 
#template = file("${path.module}/templates/userdata_t.yaml")
#  vars = {
#    vm_user_name        = var.vm_user_name
#    vm_user_password    = var.vm_user_password
#    vm_user_displayname = var.vm_user_displayname     
#    vm_user_ssh_key     = var.vm_user_ssh_key
#    vm_user_ssh_pk      = var.vm_user_ssh_pk
#
#    ansible_repo_url    = var.ansible_repo_url
#    ansible_repo_name   = var.ansible_repo_name
#    ansible_playbook    = var.ansible_playbook
#    ansible_repo_branch = var.ansible_repo_branch 
#
#    os_admin_username   = var.os_admin_username
#    os_nic1_name        = var.os_nic1_name
#
#    
#    os_admin_username   = var.os_admin_username
#    os_nic1_name        = var.os_nic1_name
#
#    
#
#    ansible_ssh_pass    = var.ansible_ssh_pass
#
#    master0_name        = "${var.vms.masters.pref}-0"
#    vcloud_vdc          = var.vcloud_vdc
#  
#    
#
#   
#
#
#  }
#}