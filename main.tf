
data "template_file" "cloudinit_master_node" {
#  template = file("./templates/userdata.yaml") 
template = file("${path.module}/templates/userdata_m.yaml")
  vars = {

    cloud_type         = "vcloud" #to let ansible know which csi to install

    vcloud_vdc         = var.vcloud_vdc
    vcloud_orgname     = var.vcloud_orgname
    vcloud_user        = var.vcloud_user
    vcloud_password    = var.vcloud_password
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
#  template = file("./templates/userdata.yaml") 
template = file("${path.module}/templates/userdata_w.yaml")
  vars = {

    #vsphere_server      = var.vsphere_server
    #vsphere_host_ip     = var.vsphere_host_ip
    #vsphere_user        = var.vsphere_user
    #vsphere_password    = var.vsphere_password
    #dcname              = var.dcname
    #dcstore_name        = var.dcstore_name
    #esxi_host_name      = var.esxi_host_name
    #vsphere_clustername = var.vsphere_clustername

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
    vsphere_csi_driver_version = var.vsphere_csi_driver_version
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

resource "vcd_vapp" "k8s_mgmt_vapp" {
  name = var.vapp_name
  metadata = {
    tag = "MGMT K8s"
   }   
}
resource "vcd_vapp_network" "k8s_mgmt_vapp_net" {
  org  = var.vcloud_orgname
  vdc  = var.vcloud_vdc

  depends_on         = [vcd_vapp.k8s_mgmt_vapp]
  name               = "${var.vapp_name}_vnet"
  vapp_name          = var.vapp_name
  gateway            = "10.10.13.1"
  netmask            = "255.255.255.0"
  dns1               = "8.8.8.8"
  dns2               = "1.1.1.1"
  org_network_name   = var.vcloud_orgvnet

  static_ip_pool {
    start_address = "10.10.13.100"
    end_address   = "10.10.13.164"
  }

}
resource "vcd_vapp_static_routing" "k8s_mgmt_vapp_net_static_routing" {
  vapp_id    = vcd_vapp.k8s_mgmt_vapp.id
  network_id = vcd_vapp_network.k8s_mgmt_vapp_net.id
  enabled    = true

  #rule {
  #  name         = "rule1"
  #  network_cidr = "192.168.100.0/24"
  #  next_hop_ip  = "192.168.100.2"
  #}

}
resource "vcd_vapp_firewall_rules" "k8s_mgmt_vapp_net_fw" {
  vapp_id        = vcd_vapp.k8s_mgmt_vapp.id
  network_id     = vcd_vapp_network.k8s_mgmt_vapp_net.id
  default_action = "drop"

  rule {
    name             = "allow-outbound"
    policy           = "allow"
    protocol         = "any"
    destination_port = "any"
    destination_ip   = "any"
    source_port      = "any"
    source_ip        = "10.10.13.0/24"
  }
    rule {
    name             = "from_vapp_to_org"
    policy           = "allow"
    protocol         = "any"
    destination_port = "any"
    destination_ip   = "192.168.100.0/24"
    source_port      = "any"
    source_ip        = "10.10.13.0/24"
  }
    rule {
    name             = "from_org_to_vapp"
    policy           = "allow"
    protocol         = "any"
    destination_port = "any"
    destination_ip   = "10.10.13.0/24"
    source_port      = "any"
    source_ip        = "192.168.100.0/24"
  }
  
}
resource "vcd_vapp_nat_rules" "k8s_mgmt_vapp_net_nat" {
  vapp_id    = vcd_vapp.k8s_mgmt_vapp.id
  network_id = vcd_vapp_network.k8s_mgmt_vapp_net.id
  nat_type   = "ipTranslation"
  enabled    = "false"

}


resource "vcd_vapp_vm" "k8s_masters_vms" {
  depends_on       = [vcd_vapp_network.k8s_mgmt_vapp_net,
                      vcd_vapp_static_routing.k8s_mgmt_vapp_net_static_routing,
                      vcd_vapp_firewall_rules.k8s_mgmt_vapp_net_fw,
                      vcd_vapp_nat_rules.k8s_mgmt_vapp_net_nat,
                      vcd_vapp_vm.k8s_workers_vms
                     ]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.masters.pref}-${count.index}"
  count            = var.vms.masters.vm_count

  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud_vmtmplname 
  
  hardware_version = "vmx-15" #Test version

  cpus             = var.vms.masters.vm_cpu_count
  memory           = var.vms.masters.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "vapp"
    name               = "${var.vapp_name}_vnet"
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = "${var.vms.masters.ip_pool[count.index]}"
  }

  guest_properties = {
    "instance-id" = "${var.vms.masters.pref}-${count.index}"
    "hostname"    = "${var.vms.masters.pref}-${count.index}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_master_node.rendered)}"
  }

}

resource "vcd_vapp_vm" "k8s_workers_vms" {
  depends_on      = [vcd_vapp_network.k8s_mgmt_vapp_net,
                    vcd_vapp_static_routing.k8s_mgmt_vapp_net_static_routing,
                    vcd_vapp_firewall_rules.k8s_mgmt_vapp_net_fw,
                    vcd_vapp_nat_rules.k8s_mgmt_vapp_net_nat
                   ]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.workers.pref}-${count.index}"
  count            = var.vms.workers.vm_count

  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud_vmtmplname

  hardware_version = "vmx-15" #Test version
      
  cpus             = var.vms.workers.vm_cpu_count
  memory           = var.vms.workers.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "vapp"
    name               = "${var.vapp_name}_vnet"
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = "${var.vms.workers.ip_pool[count.index]}"
  }

  guest_properties = {
    "instance-id" = "${var.vms.workers.pref}-${count.index}"
    "hostname"    = "${var.vms.workers.pref}-${count.index}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_worker_node.rendered)}"
  }

}
