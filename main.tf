
resource "vcd_vapp_vm" "k8s_masters_vms" {

  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_vm.k8s_workers_vms]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = "${var.vms.masters.pref}-${count.index}"
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

  guest_properties = {
    "instance-id" = "${var.vms.masters.pref}-${count.index}"
    "hostname"    = "${var.vms.masters.pref}-${count.index}"
    "user-data"   = "${base64encode(data.template_file.cloudinit_master_node.rendered)}"
  }

}

resource "vcd_vapp_vm" "k8s_workers_vms" {

  depends_on       = [vcd_vapp.k8s_mgmt_vapp,
                      vcd_vapp_org_network.vappOrgNet]
  
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
    type               = "org"
    name               = var.vcloud_orgvnet
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
