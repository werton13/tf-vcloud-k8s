resource "vcd_vapp_vm" "test_vm"{
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "test_vm"

  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud_vmtmplname 
  hardware_version = "vmx-15"
  cpus             = var.vms.masters.vm_cpu_count
  memory           = var.vms.masters.vm_ram_size
  cpu_cores        = 1

   network {
    type               = "org"
    name               = var.vcloud_orgvnet
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = "${var.vms.workers.ip_pool[0]}"
  }
  override_template_disk {
    size_in_mb      = var.system_disk_size * 1024
    bus_type        = var.system_disk_bus
  #  storage_profile = var.mod_system_disk_storage_profile
    bus_number      = 0
    unit_number     = 0
  }
   guest_properties = {
    #"instance-id" = "${var.vms.workers.pref}-${count.index}"
    "hostname"    = "testvm"
    "user-data"   = "${base64encode(data.template_file.test_node.rendered)}"
  }
}


#resource "vcd_vm_internal_disk" "engine_disk" {
##  for_each        = var.mod_add_disks
#  count           = var.vms.masters.vm_count
#  vapp_name       = vcd_vapp_vm.vm.vapp_name
#  vm_name         = vcd_vapp_vm.vm.name
#  bus_type        = each.value.bus_type
#  size_in_mb      = each.value.sizegb * 1024
#  bus_number      = each.value.bus_num
#  unit_number     = each.value.unit_num
#  storage_profile = each.value.storage_profile
#}

########### what if ???  ##########
## additional_disk_1
#
#resource "vcd_vm_internal_disk" "data1_disk" {
#depends_on       = [vcd_vapp.k8s_mgmt_vapp,
#                    vcd_vapp_org_network.vappOrgNet,
#                    vcd_vapp_vm.test_vm]
##count           = var.vms.masters.vm_count + var.vms.workers.vm_count
#count = 2
#vapp_name       = var.vapp_name
#bus_type        = var.add_disks.disk1.bus_type
#size_in_mb      = var.add_disks.disk1.sizegb * 1024
#bus_number      = var.add_disks.disk1.bus_num
#unit_number     = var.add_disks.disk1.unit_num
#
#
##vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
#vm_name = "test_vm"    
#
#}
###################################
# second way
resource "vcd_vm_internal_disk" "engine_disk" {
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                    vcd_vapp_org_network.vappOrgNet,
                    vcd_vapp_vm.test_vm]
  for_each        = var.add_disks
  vapp_name       = vcd_vapp_vm.test_vm.vapp_name
  vm_name         = vcd_vapp_vm.test_vm.name
  bus_type        = each.value.bus_type
  size_in_mb      = each.value.sizegb * 1024
  bus_number      = each.value.bus_num
  unit_number     = each.value.unit_num
  #storage_profile = each.value.storage_profile
}


###################################



#resource "vcd_vapp_vm" "k8s_masters_vms" {
#
#  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
#                      vcd_vapp_vm.k8s_workers_vms]
#  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
#  name             = "${var.vms.masters.pref}-${count.index}"
#  count            = var.vms.masters.vm_count
#
#  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
#  template_name    = var.vcloud_vmtmplname 
#  hardware_version = "vmx-15"
#  cpus             = var.vms.masters.vm_cpu_count
#  memory           = var.vms.masters.vm_ram_size
#  cpu_cores        = 1
#
#  network {
#    type               = "org"
#    name               = var.vcloud_orgvnet
#    ip_allocation_mode = "MANUAL"
#    adapter_type       = "VMXNET3"
#    ip                 = "${var.vms.masters.ip_pool[count.index]}"
#  }
#
#  guest_properties = {
#    "instance-id" = "${var.vms.masters.pref}-${count.index}"
#    "hostname"    = "${var.vms.masters.pref}-${count.index}"
#    "user-data"   = "${base64encode(data.template_file.cloudinit_master_node.rendered)}"
#  }
#
#}

#resource "vcd_vapp_vm" "k8s_workers_vms" {
#
#  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
#                      vcd_vapp_org_network.vappOrgNet]
#  
#  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
#  name             = "${var.vms.workers.pref}-${count.index}"
#  count            = var.vms.workers.vm_count
#
#  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
#  template_name    = var.vcloud_vmtmplname
#  hardware_version = "vmx-15" #Test version    
#  cpus             = var.vms.workers.vm_cpu_count
#  memory           = var.vms.workers.vm_ram_size
#  cpu_cores        = 1
#
#  network {
#    type               = "org"
#    name               = var.vcloud_orgvnet
#    ip_allocation_mode = "MANUAL"
#    adapter_type       = "VMXNET3"
#    ip                 = "${var.vms.workers.ip_pool[count.index]}"
#  }
#  guest_properties = {
#    "instance-id" = "${var.vms.workers.pref}-${count.index}"
#    "hostname"    = "${var.vms.workers.pref}-${count.index}"
#    "user-data"   = "${base64encode(data.template_file.cloudinit_worker_node.rendered)}"
#  }
#
#}
