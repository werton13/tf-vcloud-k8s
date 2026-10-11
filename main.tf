# Master node additional disks (optional based on sizegb > 0)
resource "vcd_vm_internal_disk" "mst_data1_disk" {
  depends_on = [
    vcd_vm.k8s_masters_vms
  ]
  count           = tonumber(var.disks_config.diskm1.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name       = vcd_vm.k8s_masters_vms[count.index].vapp_name
  vm_name         = local.master_nodes[count.index].name
  bus_type        = var.disks_config.diskm1.bus_type
  size_in_mb      = tonumber(var.disks_config.diskm1.sizegb) * 1024
  bus_number      = var.disks_config.diskm1.bus_num
  unit_number     = var.disks_config.diskm1.unit_num
  storage_profile = var.disks_config.diskm1.storage_profile != "" ? var.disks_config.diskm1.storage_profile : null
}

resource "vcd_vm_internal_disk" "mst_data2_disk" {
  depends_on = [
    vcd_vm.k8s_masters_vms
  ]
  count           = tonumber(var.disks_config.diskm2.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name       = vcd_vm.k8s_masters_vms[count.index].vapp_name
  vm_name         = local.master_nodes[count.index].name
  bus_type        = var.disks_config.diskm2.bus_type
  size_in_mb      = tonumber(var.disks_config.diskm2.sizegb) * 1024
  bus_number      = var.disks_config.diskm2.bus_num
  unit_number     = var.disks_config.diskm2.unit_num
  storage_profile = var.disks_config.diskm2.storage_profile != "" ? var.disks_config.diskm2.storage_profile : null
}

# Worker node additional disks (optional based on sizegb > 0)
resource "vcd_vm_internal_disk" "wrk_data1_disk" {
  depends_on = [
    vcd_vm.k8s_workers_vms
  ]
  count           = tonumber(var.disks_config.diskw1.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name       = vcd_vm.k8s_workers_vms[count.index].vapp_name
  vm_name         = local.worker_nodes[count.index].name
  bus_type        = var.disks_config.diskw1.bus_type
  size_in_mb      = tonumber(var.disks_config.diskw1.sizegb) * 1024
  bus_number      = var.disks_config.diskw1.bus_num
  unit_number     = var.disks_config.diskw1.unit_num
  storage_profile = var.disks_config.diskw1.storage_profile != "" ? var.disks_config.diskw1.storage_profile : null
}

resource "vcd_vm_internal_disk" "wrk_data2_disk" {
  depends_on = [
    vcd_vm.k8s_workers_vms
  ]
  count           = tonumber(var.disks_config.diskw2.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name       = vcd_vm.k8s_workers_vms[count.index].vapp_name
  vm_name         = local.worker_nodes[count.index].name
  bus_type        = var.disks_config.diskw2.bus_type
  size_in_mb      = tonumber(var.disks_config.diskw2.sizegb) * 1024
  bus_number      = var.disks_config.diskw2.bus_num
  unit_number     = var.disks_config.diskw2.unit_num
  storage_profile = var.disks_config.diskw2.storage_profile != "" ? var.disks_config.diskw2.storage_profile : null
}

# Master virtual machines (Standalone VMs in Org Network)
resource "vcd_vm" "k8s_masters_vms" {
  name          = local.master_nodes[count.index].name
  computer_name = local.master_nodes[count.index].name
  count         = var.vms_config.masters.vm_count
  catalog_name  = data.vcd_catalog.vcd_dp_linux.name
  template_name = var.vcloud.vm_template_name
  cpus          = var.vms_config.masters.vm_cpu_count
  memory        = var.vms_config.masters.vm_ram_size
  cpu_cores     = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.master_nodes[count.index].ip
    is_primary         = true
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  customization {
    enabled                             = true
    auto_generate_password              = false
    allow_local_admin_password          = false
    must_change_password_on_first_login = false
    initscript                          = local.customization_master_script[count.index]
  }

  guest_properties = {
    "hostname"                    = local.master_nodes[count.index].name
    "instance-id"                 = local.master_nodes[count.index].name
    "user-data"                   = base64encode(local.cloudinit_master_rendered)
    "guestinfo.userdata"          = base64encode(local.cloudinit_master_rendered)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(jsonencode({ "instance-id" = local.master_nodes[count.index].name, "local-hostname" = local.master_nodes[count.index].name }))
    "guestinfo.metadata.encoding" = "base64"
  }
}

# Worker virtual machines (Standalone VMs in Org Network)
resource "vcd_vm" "k8s_workers_vms" {
  name          = local.worker_nodes[count.index].name
  computer_name = local.worker_nodes[count.index].name
  count         = var.vms_config.workers.vm_count
  catalog_name  = data.vcd_catalog.vcd_dp_linux.name
  template_name = var.vcloud.vm_template_name
  cpus          = var.vms_config.workers.vm_cpu_count
  memory        = var.vms_config.workers.vm_ram_size
  cpu_cores     = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.worker_nodes[count.index].ip
    is_primary         = true
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  customization {
    enabled                             = true
    auto_generate_password              = false
    allow_local_admin_password          = false
    must_change_password_on_first_login = false
    initscript                          = local.customization_worker_script[count.index]
  }

  guest_properties = {
    "hostname"                    = local.worker_nodes[count.index].name
    "instance-id"                 = local.worker_nodes[count.index].name
    "user-data"                   = base64encode(local.cloudinit_worker_rendered)
    "guestinfo.userdata"          = base64encode(local.cloudinit_worker_rendered)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(jsonencode({ "instance-id" = local.worker_nodes[count.index].name, "local-hostname" = local.worker_nodes[count.index].name }))
    "guestinfo.metadata.encoding" = "base64"
  }
}

# Wait for master and worker nodes to finish booting and guest customization before creating DVM
resource "time_sleep" "wait_for_nodes_ready" {
  depends_on = [
    vcd_vm.k8s_masters_vms,
    vcd_vm.k8s_workers_vms,
    vcd_vm_internal_disk.mst_data1_disk,
    vcd_vm_internal_disk.mst_data2_disk,
    vcd_vm_internal_disk.wrk_data1_disk,
    vcd_vm_internal_disk.wrk_data2_disk
  ]

  create_duration = "90s"
}

# Deployment workstation VM (DVM) (Standalone VM in Org Network)
resource "vcd_vm" "dvm" {
  depends_on = [
    time_sleep.wait_for_nodes_ready
  ]
  name          = local.dvm_name
  computer_name = local.dvm_name
  catalog_name  = data.vcd_catalog.vcd_dp_linux.name
  template_name = var.vcloud.vm_template_name
  cpus          = var.vms_config.dvm.vm_cpu_count
  memory        = var.vms_config.dvm.vm_ram_size
  cpu_cores     = 1

  network {
    type               = "org"
    name               = var.vcloud.orgvnet_name
    ip_allocation_mode = "MANUAL"
    adapter_type       = "VMXNET3"
    ip                 = local.dvm_ip
    is_primary         = true
  }

  override_template_disk {
    size_in_mb  = tonumber(var.disks_config.osdisk.sizegb) * 1024
    bus_type    = var.disks_config.osdisk.bus_type
    bus_number  = var.disks_config.osdisk.bus_num
    unit_number = var.disks_config.osdisk.unit_num
  }

  customization {
    enabled                             = true
    auto_generate_password              = false
    allow_local_admin_password          = false
    must_change_password_on_first_login = false
    initscript                          = local.customization_dvm_script
  }

  guest_properties = {
    "hostname"                    = local.dvm_name
    "instance-id"                 = local.dvm_name
    "user-data"                   = base64encode(local.cloudinit_dvm_rendered)
    "guestinfo.userdata"          = base64encode(local.cloudinit_dvm_rendered)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(jsonencode({ "instance-id" = local.dvm_name, "local-hostname" = local.dvm_name }))
    "guestinfo.metadata.encoding" = "base64"
  }
}
