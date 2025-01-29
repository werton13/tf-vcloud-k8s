data "vcd_catalog" "vcd_dp_linux" {
    org  = var.vcloud.orgname
    name = var.vcloud.catalogname
}

data "vcd_edgegateway" "egw" {
  name = var.vcloud.edgegw
}

data "template_file" "cloudinit_dvm" {
template = file("${path.module}/templates/userdata_dvm.yaml")
  vars = {

    cloud_type         = "vcloud" #to let ansible know which csi to install

    vcloud_vdc                 = var.vcloud.vdc
    vcloud_orgname             = var.vcloud.orgname
    vcloud_user                = var.vcloud.admin
    vcloud_password            = var.vcloud.admin_pwd
    vcloud_csiadmin_username   = var.vcloud.csi_svc
    vcloud_csiadmin_password   = var.vcloud.csi_svc_pwd
    vcloud_url                 = var.vcloud.server_fqdn
    vcloud_ip                  = var.vcloud.server_ip
    #vcloud_fqdn        = "${substr(var.vcloud_url, 8, -4}" #2deprecate?
    vcloud_catalogname         = var.vcloud.catalogname
    vcloud_vmtmplname          = var.vcloud.vm_template_name
    vcloud_orgvnet             = var.vcloud.orgvnet_name
    vapp_name                  = var.vcloud.vapp_name

    vm_user_name               = var.os_config.vm_user_name
    vm_user_password           = var.os_config.vm_user_password
    vm_user_displayname        = var.os_config.vm_user_displayname     
    vm_user_ssh_key            = var.os_config.vm_user_ssh_key
    #vm_user_ssh_pk             = var.os_config.vm_user_ssh_pk
    ansible_ssh_pass           = var.os_config.ansible_ssh_pass
    def_dns                    = var.os_config.def_dns
    env_dns1                   = var.os_config.env_dns1
    env_dns2                   = var.os_config.env_dns2

    ansible_repo_url           = var.ansible.git_repo.repo_url
    ansible_repo_name          = var.ansible.git_repo.repo_name
    ansible_repo_branch        = var.ansible.git_repo.repo_branch
    ansible_playbook           = var.ansible.git_repo.playbook_name
    
    os_admin_username          = var.os_config.vm_user_name
    os_nic1_name               = var.os_config.os_nic1_name
    docker_mirror              = var.os_config.docker_mirror

    k8s_cluster_name           = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}"
    k8s_cluster_id             = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}"

    #k8s_controlPlane_Endpoint  = var.kubernetes.cluster.controlPlane_Endpoint #!
    k8s_controlPlane_Endpoint  = "${cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb) )}"
    k8s_service_subnet         = var.kubernetes.cni.svc_subnet
    k8s_pod_subnet             = var.kubernetes.cni.pod_subnet
    calico_network_cidr_blocksize = var.kubernetes.cni.calico_network_cidr_blocksize
    sc_storage_policy_name     = var.kubernetes.pvc.sc_storage_policy_name
    sc_name                    = var.kubernetes.pvc.sc_name
    k8s_version                = var.kubernetes.cluster.version

    k8s_ver                    = (lookup (var.versions, var.kubernetes.cluster.version)).full
    k8s_version_short          = (lookup (var.versions, var.kubernetes.cluster.version)).short
    calico_version             = (lookup (var.versions, var.kubernetes.cluster.version)).cni.calico_version
    tigera_version             = (lookup (var.versions, var.kubernetes.cluster.version)).cni.tigera_version
    #calicoctl_url              = (lookup (var.versions, var.kubernetes.cluster.version)).cni.calicoctl_url
    vsphere_csi_driver_version = (lookup (var.versions, var.kubernetes.cluster.version)).csi.driver_version
    cpi_tag                    = (lookup (var.versions, var.kubernetes.cluster.version)).csi.cpi_tag
    cpi_url                    = (lookup (var.versions, var.kubernetes.cluster.version)).csi.cpi_url
    ETCD_RELEASES_URL          = (lookup (var.versions, var.kubernetes.cluster.version)).etcd.ETCD_RELEASES_URL
    etcd_ver                   = (lookup (var.versions, var.kubernetes.cluster.version)).etcd.etcd_ver
    helm_version               = (lookup (var.versions, var.kubernetes.cluster.version)).helm.helm_version
    helm_repo_path             = (lookup (var.versions, var.kubernetes.cluster.version)).helm.helm_repo_path
 
  
    ingress_ext_fqdn                  = var.kubernetes.ingress.ext_fqdn
    ingress_controller_nodeport_http  = var.kubernetes.ingress.controller_nodeport_http 
    ingress_controller_nodeport_https = var.kubernetes.ingress.controller_nodeport_https  
        
    master_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst" 
    worker_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk"

    hosts_entry0        = "${var.vcloud.server_ip}  ${split("/", var.vcloud.server_fqdn)[2]}"
    #hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  ${var.vms.dvm.pref}"
    hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  dvm"
    
    #dvm_name            = "${var.vms.dvm.pref}"
    dvm_name            = "dvm"
    #worker0_name        = "${var.vms.workers.pref}-0" # to deprecate?
    worker0_name        = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk-${format("%02s",  1)}"
     
    #lb0_ip              = "${cidrhost(var.os_config.vm_ip_cidr,2)}" # dont need here?
    master0_ip          = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.m_node))}"
    master1_ip          = "${cidrhost(var.os_config.vm_ip_cidr,(tonumber(var.ip_plan.m_node)+1) )}"
    master2_ip          = "${cidrhost(var.os_config.vm_ip_cidr,(tonumber(var.ip_plan.m_node)+2) )}"

    workers_count       = var.vms_config.workers.vm_count
    masters_count       = var.vms_config.masters.vm_count
    lb_count            = var.vcloud.lbvm_count

    obs_type              = var.obs_config.common.obs_type

    telegram_rcv_name     = "${var.obs_config.common.obs_type}" == "prom_stack" ? "${var.obs_config.prom_stack.alertmanager.telegram_receiver_name}" : ""
    telegram_bot_token    = "${var.obs_config.common.obs_type}" == "prom_stack" ? "${var.obs_config.prom_stack.alertmanager.telegram_bot_token}" : ""
    telegram_chat_id      = "${var.obs_config.common.obs_type}" == "prom_stack" ? "${var.obs_config.prom_stack.alertmanager.telegram_chatid}" : ""
    #    
    vm_stack_type         = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.type}" : ""
    remoteWriteUrl        = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.remoteWriteUrl}" : ""
    remoteWriteUsername   = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.remoteWriteUsername}" : ""
    remoteWritePassword   = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.remoteWritePassword}" : ""
    etcdProxyMainImageURL = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.etcdProxyMainImageURL}" : ""
    etcdProxyInitImageURL = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.etcdProxyInitImageURL}" : ""
    label_env_name        = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.label_env_name}" : ""
    label_dctr_name       = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.label_dctr_name}" : ""
    label_project_name    = "${var.obs_config.common.obs_type}" == "vm_stack"  ? "${var.obs_config.vm_stack.label_project_name}" : ""


  }
}


data "template_file" "cloudinit_master_node" {
#  template = file("./templates/userdata.yaml") 
template = file("${path.module}/templates/userdata_m.yaml")
  vars = {

    cloud_type         = "vcloud" #to let ansible know which csi to install

    vm_user_name        = var.os_config.vm_user_name
    vm_user_password    = var.os_config.vm_user_password
    vm_user_displayname = var.os_config.vm_user_displayname     
    vm_user_ssh_key     = var.os_config.vm_user_ssh_key
    ansible_ssh_pass    = var.os_config.ansible_ssh_pass  

    master_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst" 
    worker_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk"

    workers_count       = var.vms_config.workers.vm_count
    masters_count       = var.vms_config.masters.vm_count

    master0_ip          = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.m_node))}"

    hosts_entry0        = "${var.vcloud.server_ip}  ${split("/", var.vcloud.server_fqdn)[2]}"
    #hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  ${var.vms.dvm.pref}"
    hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  dvm"
    
  }
}

data "template_file" "cloudinit_worker_node" {
template = file("${path.module}/templates/userdata_w.yaml")
  vars = {

    vm_user_name        = var.os_config.vm_user_name
    vm_user_password    = var.os_config.vm_user_password
    vm_user_displayname = var.os_config.vm_user_displayname     
    vm_user_ssh_key     = var.os_config.vm_user_ssh_key
    ansible_ssh_pass    = var.os_config.ansible_ssh_pass

    master_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst" 
    worker_pref         =  "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk"

    workers_count       = var.vms_config.workers.vm_count
    masters_count       = var.vms_config.masters.vm_count

    master0_ip          = "${cidrhost(var.os_config.vm_ip_cidr,4)}"

    hosts_entry0        = "${var.vcloud.server_ip}  ${split("/", var.vcloud.server_fqdn)[2]}"
    #hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  ${var.vms.dvm.pref}"
    hosts_entry1        = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.dvm))}  dvm"
  }
}