# Master node additional disks (optional based on sizegb > 0)
resource "vcd_vm_internal_disk" "mst_data1_disk" {
  depends_on = [
    vcd_vapp_vm.k8s_masters_vms
  ]
  count           = tonumber(var.disks_config.diskm1.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name       = vcd_vapp.k8s_vapp.name
  vm_name         = local.master_nodes[count.index].name
  bus_type        = var.disks_config.diskm1.bus_type
  size_in_mb      = tonumber(var.disks_config.diskm1.sizegb) * 1024
  bus_number      = var.disks_config.diskm1.bus_num
  unit_number     = var.disks_config.diskm1.unit_num
  storage_profile = var.disks_config.diskm1.storage_profile != "" ? var.disks_config.diskm1.storage_profile : null
}

resource "vcd_vm_internal_disk" "mst_data2_disk" {
  depends_on = [
    vcd_vapp_vm.k8s_masters_vms
  ]
  count           = tonumber(var.disks_config.diskm2.sizegb) > 0 ? var.vms_config.masters.vm_count : 0
  vapp_name       = vcd_vapp.k8s_vapp.name
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
    vcd_vapp_vm.k8s_workers_vms
  ]
  count           = tonumber(var.disks_config.diskw1.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name       = vcd_vapp.k8s_vapp.name
  vm_name         = local.worker_nodes[count.index].name
  bus_type        = var.disks_config.diskw1.bus_type
  size_in_mb      = tonumber(var.disks_config.diskw1.sizegb) * 1024
  bus_number      = var.disks_config.diskw1.bus_num
  unit_number     = var.disks_config.diskw1.unit_num
  storage_profile = var.disks_config.diskw1.storage_profile != "" ? var.disks_config.diskw1.storage_profile : null
}

resource "vcd_vm_internal_disk" "wrk_data2_disk" {
  depends_on = [
    vcd_vapp_vm.k8s_workers_vms
  ]
  count           = tonumber(var.disks_config.diskw2.sizegb) > 0 ? var.vms_config.workers.vm_count : 0
  vapp_name       = vcd_vapp.k8s_vapp.name
  vm_name         = local.worker_nodes[count.index].name
  bus_type        = var.disks_config.diskw2.bus_type
  size_in_mb      = tonumber(var.disks_config.diskw2.sizegb) * 1024
  bus_number      = var.disks_config.diskw2.bus_num
  unit_number     = var.disks_config.diskw2.unit_num
  storage_profile = var.disks_config.diskw2.storage_profile != "" ? var.disks_config.diskw2.storage_profile : null
}

# Master virtual machines (in the shared cluster vApp, attached to the Org Network)
resource "vcd_vapp_vm" "k8s_masters_vms" {
  depends_on = [
    vcd_vapp_org_network.k8s_vapp_orgnet
  ]
  vapp_name     = vcd_vapp.k8s_vapp.name
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

  # Required by the vCloud CSI driver: it finds attached disks inside the guest by SCSI UUID
  set_extra_config {
    key   = "disk.EnableUUID"
    value = "TRUE"
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
    "user-data"                   = base64encode(local.cloudinit_master_rendered[count.index])
    "guestinfo.userdata"          = base64encode(local.cloudinit_master_rendered[count.index])
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(jsonencode({ "instance-id" = local.master_nodes[count.index].name, "local-hostname" = local.master_nodes[count.index].name }))
    "guestinfo.metadata.encoding" = "base64"
  }
}

# Worker virtual machines (in the shared cluster vApp, attached to the Org Network)
resource "vcd_vapp_vm" "k8s_workers_vms" {
  depends_on = [
    vcd_vapp_org_network.k8s_vapp_orgnet
  ]
  vapp_name     = vcd_vapp.k8s_vapp.name
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

  # Required by the vCloud CSI driver: it finds attached disks inside the guest by SCSI UUID
  set_extra_config {
    key   = "disk.EnableUUID"
    value = "TRUE"
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
    "user-data"                   = base64encode(local.cloudinit_worker_rendered[count.index])
    "guestinfo.userdata"          = base64encode(local.cloudinit_worker_rendered[count.index])
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(jsonencode({ "instance-id" = local.worker_nodes[count.index].name, "local-hostname" = local.worker_nodes[count.index].name }))
    "guestinfo.metadata.encoding" = "base64"
  }
}

# Wait for master and worker nodes to finish booting and guest customization before creating DVM
resource "time_sleep" "wait_for_nodes_ready" {
  depends_on = [
    vcd_vapp_vm.k8s_masters_vms,
    vcd_vapp_vm.k8s_workers_vms,
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

# -----------------------------------------------------------------------------
# Optional: vcd-k8s-node-controller ownership guard
# -----------------------------------------------------------------------------
# Enabling the controller hands worker scaling and worker LB pool membership over
# to the controller/CRD. This check warns on every plan/apply while it is enabled.
check "node_controller_ownership_warning" {
  assert {
    condition     = !var.node_controller.enabled
    error_message = "WARNING: vcd-k8s-node-controller is enabled. Terraform no longer owns worker scaling or worker LB pool membership. Do not use terraform apply to change worker count, node configuration, or LB membership; use the K8sWorkerPool CRD instead."
  }
}

# Planning-time hard guard. The controller is optional, so this resource is only
# created when it is enabled.
resource "terraform_data" "node_controller_guard" {
  count = var.node_controller.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.node_controller.acknowledge_terraform_ownership_loss
      error_message = "Set node_controller.acknowledge_terraform_ownership_loss = true to confirm that Terraform will no longer manage worker scaling or worker LB pool membership after the controller is enabled."
    }

    precondition {
      condition = !var.node_controller.create_vcd_secret || (
        var.node_controller.vcd_user != "" && var.node_controller.vcd_password != ""
      )
      error_message = "node_controller.create_vcd_secret = true requires node_controller.vcd_user and node_controller.vcd_password. Use a dedicated vCD service account with VM and LB pool permissions, or set create_vcd_secret = false and pre-create the Secret."
    }
  }
}

# -----------------------------------------------------------------------------
# NSX-T VIP guard
# -----------------------------------------------------------------------------
# NSX-T has no Edge load balancer in this module: kube-vip owns the KubeAPI and
# ingress VIPs. These checks fail the plan early instead of producing a cluster
# with an unreachable control plane.
resource "terraform_data" "nsxt_vip_guard" {
  count = local.use_kube_vip ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.kubernetes.vip.public_ip != ""
      error_message = "kubernetes.vip.public_ip is required when vcloud.network_type = \"nsx-t\" (Edge Gateway on IP Spaces has no default external IP)."
    }

    precondition {
      condition     = var.kubernetes.vip.kube_vip_address == "" || var.kubernetes.vip.kube_vip_address == local.kubeapi_vip
      error_message = "kubernetes.vip.kube_vip_address must be empty (computed) or equal to ip_plan.kubeapi_lb / k8s_controlPlane_Endpoint."
    }

    precondition {
      condition     = var.kubernetes.vip.ingress_lb_ip == "" || var.kubernetes.vip.ingress_lb_ip == local.ingress_vip
      error_message = "kubernetes.vip.ingress_lb_ip must be empty (computed) or equal to ip_plan.ingress_lb."
    }
  }
}
