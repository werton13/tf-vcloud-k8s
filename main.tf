#resource "vcd_vm_internal_disk" "data1_disk" {
#  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
#                      vcd_vapp_org_network.vappOrgNet,
#                      vcd_vapp_vm.k8s_masters_vms]
#  count           = var.vms.masters.vm_count + var.vms.workers.vm_count
#  #count = 2
#  vapp_name       = var.vapp_name
#  bus_type        = var.add_disks.disk1.bus_type
#  size_in_mb      = var.add_disks.disk1.sizegb * 1024
#  bus_number      = var.add_disks.disk1.bus_num
#  unit_number     = var.add_disks.disk1.unit_num
#  vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
#   
#}

resource "vcd_vm_internal_disk" "mst_data1_disk" {
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet,
                      vcd_vapp_vm.k8s_masters_vms]
  count           = var.vms.masters.vm_count
  #count = 2
  vapp_name       = var.vapp_name
  bus_type        = var.add_disks.diskm1.bus_type
  size_in_mb      = var.add_disks.diskm1.sizegb * 1024
  bus_number      = var.add_disks.diskm1.bus_num
  unit_number     = var.add_disks.diskm1.unit_num
  #vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
  vm_name = "${var.vms.masters.pref}-0${count.index + 1}"  
}

resource "vcd_vm_internal_disk" "mst_data2_disk" {
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet,
                      vcd_vapp_vm.k8s_masters_vms]
  count           = var.vms.masters.vm_count
  #count = 2
  vapp_name       = var.vapp_name
  bus_type        = var.add_disks.diskm2.bus_type
  size_in_mb      = var.add_disks.diskm2.sizegb * 1024
  bus_number      = var.add_disks.diskm2.bus_num
  unit_number     = var.add_disks.diskm2.unit_num
  #vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
  vm_name = "${var.vms.masters.pref}-0${count.index + 1}"  
}

resource "vcd_vm_internal_disk" "wrk_data1_disk" {
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet,
                      vcd_vapp_vm.k8s_masters_vms]
  count           = var.vms.masters.vm_count
  #count = 2
  vapp_name       = var.vapp_name
  bus_type        = var.add_disks.diskw1.bus_type
  size_in_mb      = var.add_disks.diskw1.sizegb * 1024
  bus_number      = var.add_disks.diskw1.bus_num
  unit_number     = var.add_disks.diskw1.unit_num
  #vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
  vm_name = "${var.vms.workers.pref}-${format("%02s", (count.index + 1))}"             
}

resource "vcd_vm_internal_disk" "wrk_data2_disk" {
  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet,
                      vcd_vapp_vm.k8s_masters_vms]
  count           = var.vms.masters.vm_count
  #count = 2
  vapp_name       = var.vapp_name
  bus_type        = var.add_disks.diskw2.bus_type
  size_in_mb      = var.add_disks.diskw2.sizegb * 1024
  bus_number      = var.add_disks.diskw2.bus_num
  unit_number     = var.add_disks.diskw2.unit_num
  #vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
  vm_name = "${var.vms.workers.pref}-${format("%02s", (count.index + 1))}"             
}



#resource "vcd_vm_internal_disk" "data2_disk" {
#  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
#                      vcd_vapp_org_network.vappOrgNet,
#                      vcd_vapp_vm.k8s_masters_vms]
#  count           = var.vms.masters.vm_count + var.vms.workers.vm_count
#  #count = 2
#  vapp_name       = var.vapp_name
#  bus_type        = var.add_disks.disk2.bus_type
#  size_in_mb      = var.add_disks.disk2.sizegb * 1024
#  bus_number      = var.add_disks.disk2.bus_num
#  unit_number     = var.add_disks.disk2.unit_num
#  vm_name = count.index <= (var.vms.masters.vm_count -1) ? "${var.vms.masters.pref}-${count.index}" : "${var.vms.workers.pref}-${count.index -(var.vms.masters.vm_count) }"
#  
#}


resource "vcd_vapp_vm" "k8s_masters_vms" {

  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_vm.k8s_workers_vms]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.masters.pref}-0${count.index + 1}"
  count            = var.vms.masters.vm_count

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
    ip                 = "${var.vms.masters.ip_pool[count.index]}"
  }
  override_template_disk {
    size_in_mb      = var.system_disk_size * 1024
    bus_type        = var.system_disk_bus
  #  storage_profile = var.mod_system_disk_storage_profile
    bus_number      = 0
    unit_number     = 0
  }

  guest_properties = {
    "instance-id" = "${var.vms.masters.pref}-0${count.index + 1}"
    "hostname"    = "${var.vms.masters.pref}-0${count.index + 1}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_master_node.rendered)}"
  }

}

resource "vcd_vapp_vm" "k8s_workers_vms" {

  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet]
  
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.workers.pref}-${format("%02s", (count.index + 1))}"
  count            = var.vms.workers.vm_count

  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud_vmtmplname
  hardware_version = "vmx-15" #Test version    
  cpus             = var.vms.workers.vm_cpu_count
  memory           = var.vms.workers.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "org"
    name               = var.vcloud_orgvnet
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = "${var.vms.workers.ip_pool[count.index]}"
  }
  override_template_disk {
    size_in_mb      = var.system_disk_size * 1024
    bus_type        = var.system_disk_bus
  #  storage_profile = var.mod_system_disk_storage_profile
    bus_number      = 0
    unit_number     = 0
  }

  guest_properties = {
    "instance-id" = "${var.vms.workers.pref}-${format("%02s", (count.index + 1))}"
    "hostname"    = "${var.vms.workers.pref}-${format("%02s", (count.index + 1))}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_worker_node.rendered)}"
  }

}

### -- the last VM is deployment VM, from there all Ansible automation will run
resource "vcd_vapp_vm" "dvm" {

  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_vm.k8s_masters_vms]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.dvm.pref}"
  

  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud_vmtmplname 
  hardware_version = "vmx-15"
  cpus             = var.vms.dvm.vm_cpu_count
  memory           = var.vms.dvm.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "org"
    name               = var.vcloud_orgvnet
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = "${var.vms.dvm.ip_pool[0]}"
  }
  override_template_disk {
    size_in_mb      = var.system_disk_size * 1024
    bus_type        = var.system_disk_bus
  #  storage_profile = var.mod_system_disk_storage_profile
    bus_number      = 0
    unit_number     = 0
  }

  guest_properties = {
    "instance-id" = "${var.vms.dvm.pref}"
    "hostname"    = "${var.vms.dvm.pref}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_dvm.rendered)}"
  }

}

