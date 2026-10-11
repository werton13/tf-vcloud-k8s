# Master node additional disks (optional based on sizegb > 0)
resource "vcd_vm_internal_disk" "mst_data1_disk" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet,
    vcd_vapp_vm.k8s_masters_vms
  ]
  count       = tonumber(var.disks_config.diskm1.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name   = var.vcloud.vapp_name
  bus_type    = var.disks_config.diskm1.bus_type
  size_in_mb  = tonumber(var.disks_config.diskm1.sizegb) * 1024
  bus_number  = var.disks_config.diskm1.bus_num
  unit_number = var.disks_config.diskm1.unit_num
  vm_name     = local.master_nodes[count.index].name
}

resource "vcd_vm_internal_disk" "mst_data2_disk" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet,
    vcd_vapp_vm.k8s_masters_vms
  ]
  count       = tonumber(var.disks_config.diskm2.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name   = var.vcloud.vapp_name
  bus_type    = var.disks_config.diskm2.bus_type
  size_in_mb  = tonumber(var.disks_config.diskm2.sizegb) * 1024
  bus_number  = var.disks_config.diskm2.bus_num
  unit_number = var.disks_config.diskm2.unit_num
  vm_name     = local.master_nodes[count.index].name
}

# Worker node additional disks (optional based on sizegb > 0)
resource "vcd_vm_internal_disk" "wrk_data1_disk" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet,
    vcd_vapp_vm.k8s_workers_vms
  ]
  count       = tonumber(var.disks_config.diskw1.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name   = var.vcloud.vapp_name
  bus_type    = var.disks_config.diskw1.bus_type
  size_in_mb  = tonumber(var.disks_config.diskw1.sizegb) * 1024
  bus_number  = var.disks_config.diskw1.bus_num
  unit_number = var.disks_config.diskw1.unit_num
  vm_name     = local.worker_nodes[count.index].name
}

resource "vcd_vm_internal_disk" "wrk_data2_disk" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet,
    vcd_vapp_vm.k8s_workers_vms
  ]
  count       = tonumber(var.disks_config.diskw2.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name   = var.vcloud.vapp_name
  bus_type    = var.disks_config.diskw2.bus_type
  size_in_mb  = tonumber(var.disks_config.diskw2.sizegb) * 1024
  bus_number  = var.disks_config.diskw2.bus_num
  unit_number = var.disks_config.diskw2.unit_num
  vm_name     = local.worker_nodes[count.index].name
}

# Master virtual machines
resource "vcd_vapp_vm" "k8s_masters_vms" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet
  ]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = local.master_nodes[count.index].name
  count            = var.vms_config.masters.vm_count
  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud.vm_template_name
  hardware_version = "vmx-15"
  cpus             = var.vms_config.masters.vm_cpu_count
  memory           = var.vms_config.masters.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.master_nodes[count.index].ip
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  guest_properties = {
    "instance-id" = local.master_nodes[count.index].name
    "hostname"    = local.master_nodes[count.index].name
    "user-data"   = base64encode(local.cloudinit_master_rendered)
  }
}

# Worker virtual machines
resource "vcd_vapp_vm" "k8s_workers_vms" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_org_network.vappOrgNet
  ]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = local.worker_nodes[count.index].name
  count            = var.vms_config.workers.vm_count
  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud.vm_template_name
  hardware_version = "vmx-15"
  cpus             = var.vms_config.workers.vm_cpu_count
  memory           = var.vms_config.workers.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.worker_nodes[count.index].ip
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  guest_properties = {
    "instance-id" = local.worker_nodes[count.index].name
    "hostname"    = local.worker_nodes[count.index].name
    "user-data"   = base64encode(local.cloudinit_worker_rendered)
  }
}

# Deployment workstation VM (DVM)
resource "vcd_vapp_vm" "dvm" {
  depends_on = [
    vcd_vapp.k8s_mgmt_vapp,
    vcd_vapp_vm.k8s_masters_vms,
    vcd_vapp_vm.k8s_workers_vms
  ]
  vapp_name        = vcd_vapp.k8s_mgmt_vapp.name
  name             = local.dvm_name
  catalog_name     = data.vcd_catalog.vcd_dp_linux.name
  template_name    = var.vcloud.vm_template_name
  hardware_version = "vmx-15"
  cpus             = var.vms_config.dvm.vm_cpu_count
  memory           = var.vms_config.dvm.vm_ram_size
  cpu_cores        = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.dvm_ip
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  guest_properties = {
    "instance-id" = local.dvm_name
    "hostname"    = local.dvm_name
    "user-data"   = base64encode(local.cloudinit_dvm_rendered)
  }
}
