locals {
  # Master nodes metadata
  master_nodes = [
    for i in range(tonumber(var.vms_config.masters.vm_count)) : {
      name = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst-${format("%02s", i + 1)}"
      ip   = cidrhost(var.os_config.vm_ip_cidr, i + tonumber(var.ip_plan.m_node))
    }
  ]

  # Worker nodes metadata
  worker_nodes = [
    for i in range(tonumber(var.vms_config.workers.vm_count)) : {
      name = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk-${format("%02s", i + 1)}"
      ip   = cidrhost(var.os_config.vm_ip_cidr, i + tonumber(var.ip_plan.w_node))
    }
  ]

  # DVM host metadata
  dvm_ip   = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.dvm))
  dvm_name = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-dvm"

  # vCloud API host entry
  vcloud_fqdn_entry = "${var.vcloud.server_ip}  ${split("/", var.vcloud.server_fqdn)[2]}"

  # Automatic Edge Gateway Public IP and External Network discovery
  egw_public_ip = try(var.vcloud.public_ip, "") != "" ? var.vcloud.public_ip : data.vcd_edgegateway.egw.default_external_network_ip

  egw_ext_net_name = try(var.vcloud.external_network_name, "") != "" ? var.vcloud.external_network_name : coalesce(
    try([
      for net in data.vcd_edgegateway.egw.external_network : net.name
      if anytrue([for s in net.subnet : s.use_for_default_route])
    ][0], null),
    try(tolist(data.vcd_edgegateway.egw.external_network)[0].name, "")
  )

  # Hosts file content
  hosts_content = join("\n", concat(
    [
      "      # vCloud API entry",
      "      ${local.vcloud_fqdn_entry}",
      "      # DVM host",
      "      ${local.dvm_ip}  ${local.dvm_name}",
      "      # Master nodes"
    ],
    [for node in local.master_nodes : "      ${node.ip}  ${node.name}"],
    [
      "      # Worker nodes"
    ],
    [for node in local.worker_nodes : "      ${node.ip}  ${node.name}"]
  ))

  # Inventory file content for DVM (credentials use Ansible Vault placeholders)
  inventory_content = <<-EOT
    [dvm]
    ${local.dvm_name}

    [masters]
    %{for node in local.master_nodes~}
    ${node.name} ansible_host=${node.ip}
    %{endfor~}

    [workers]
    %{for node in local.worker_nodes~}
    ${node.name} ansible_host=${node.ip}
    %{endfor~}

    [k8s-nodes:children]
    masters
    workers

    [k8s-nodes:vars]
    ansible_connection=ssh
    ansible_user="__VAULT_OS_ADMIN__"
    ansible_ssh_pass="__VAULT_OS_PASSWORD__"
    ansible_sudo_pass="__VAULT_OS_PASSWORD__"
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'

    [dvm:vars]
    ansible_connection=local
    ansible_user="__VAULT_OS_ADMIN__"
    ansible_sudo_pass="__VAULT_OS_PASSWORD__"
  EOT

  # Target K8s version details from matrix
  target_version = lookup(var.versions, var.kubernetes.cluster.version)

  # Cluster variables content (YAML)
  cluster_vars_content = <<-EOT
    ---
    # Kubernetes Cluster Identity
    k8s_cluster_name: "${var.project.owner_org}-${var.project.name}-${var.project.env_name}"
    k8s_cluster_id: "${var.project.owner_org}-${var.project.name}-${var.project.env_name}"
    k8s_version: "${var.kubernetes.cluster.version}"
    k8s_version_short: "${local.target_version.short}"
    k8s_ver: "${local.target_version.full}"
    k8s_controlPlane_Endpoint: "${cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb))}"

    # Networking / CNI
    k8s_service_subnet: "${var.kubernetes.cni.svc_subnet}"
    k8s_pod_subnet: "${var.kubernetes.cni.pod_subnet}"
    calico_network_cidr_blocksize: "${var.kubernetes.cni.calico_network_cidr_blocksize}"
    calico_version: "${try(local.target_version.cni.calico_version, "v3.31.5")}"
    tigera_version: "${try(local.target_version.cni.tigera_version, "v1.40.8")}"

    # Storage / CSI
    cloud_type: "vcloud"
    vcloud_vdc: "${var.vcloud.vdc}"
    vcloud_orgname: "${var.vcloud.orgname}"
    vcloud_url: "${var.vcloud.server_fqdn}"
    vcloud_ip: "${var.vcloud.server_ip}"
    vcloud_csiadmin_username: "${var.vcloud.csi_svc}"
    vcloud_csiadmin_password: "${var.vcloud.csi_svc_pwd}"
    vcloud_catalogname: "${var.vcloud.catalogname}"
    vcloud_vmtmplname: "${var.vcloud.vm_template_name}"
    vcloud_orgvnet: "${var.vcloud.orgvnet_name}"
    vapp_name: "${var.vcloud.vapp_name}"
    sc_storage_policy_name: "${var.kubernetes.pvc.sc_storage_policy_name}"
    sc_name: "${var.kubernetes.pvc.sc_name}"

    # OS and System Configuration
    os_admin_username: "${var.os_config.vm_user_name}"
    os_nic1_name: "${var.os_config.os_nic1_name}"
    def_dns: "${var.os_config.def_dns}"
    env_dns1: "${var.os_config.env_dns1}"
    env_dns2: "${var.os_config.env_dns2}"
    env_dns3: "${try(var.os_config.env_dns3, "")}"

    # Ingress Controller
    ingress_controller_nodeport_http: "${var.kubernetes.ingress.controller_nodeport_http}"
    ingress_controller_nodeport_https: "${var.kubernetes.ingress.controller_nodeport_https}"
    ingress_ext_fqdn: "${var.kubernetes.ingress.ext_fqdn}"

    # Observability / Monitoring
    obs_type: "${var.obs_config.common.obs_type}"
    vm_stack_type: "${try(var.obs_config.vm_stack.type, "operator")}"
    remoteWriteUrl: "${try(var.obs_config.vm_stack.remoteWriteUrl, "")}"
    remoteWriteUsername: "${try(var.obs_config.vm_stack.remoteWriteUsername, "")}"
    remoteWritePassword: "${try(var.obs_config.vm_stack.remoteWritePassword, "")}"
    label_env_name: "${try(var.obs_config.vm_stack.label_env_name, var.project.env_name)}"
    label_project_name: "${try(var.obs_config.vm_stack.label_project_name, var.project.name)}"
    env_name: "${try(var.obs_config.vm_stack.label_env_name, var.project.env_name)}"
    project_name: "${try(var.obs_config.vm_stack.label_project_name, var.project.name)}"
    k8s_type: "${try(var.obs_config.vm_stack.k8s_type, "vcloud")}"
    dctr_name: "${try(var.obs_config.vm_stack.dctr_name, var.vcloud.vdc)}"

    # Node Topology
    masters_count: ${var.vms_config.masters.vm_count}
    workers_count: ${var.vms_config.workers.vm_count}
    master_pref: "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst"
    worker_pref: "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk"
    master0_ip: "${local.master_nodes[0].ip}"
    worker0_name: "${local.worker_nodes[0].name}"
  EOT

  # Rendered cloud-init files
  dns_servers_list = join(" ", compact([var.os_config.env_dns1, var.os_config.env_dns2, try(var.os_config.env_dns3, "")]))

  cloudinit_master_rendered = templatefile("${path.module}/templates/userdata_m.yaml", {
    vm_user_name        = var.os_config.vm_user_name
    vm_user_displayname = var.os_config.vm_user_displayname
    vm_user_password    = var.os_config.vm_user_password
    vm_user_ssh_key     = try(var.os_config.vm_user_ssh_key, "")
    hosts_content       = local.hosts_content
    dns_servers         = local.dns_servers_list
  })

  cloudinit_worker_rendered = templatefile("${path.module}/templates/userdata_w.yaml", {
    vm_user_name        = var.os_config.vm_user_name
    vm_user_displayname = var.os_config.vm_user_displayname
    vm_user_password    = var.os_config.vm_user_password
    vm_user_ssh_key     = try(var.os_config.vm_user_ssh_key, "")
    hosts_content       = local.hosts_content
    dns_servers         = local.dns_servers_list
  })

  # Cluster node IPs list for health-check / polling
  cluster_node_ips = join(" ", [for node in concat(local.master_nodes, local.worker_nodes) : node.ip])

  cloudinit_dvm_rendered = templatefile("${path.module}/templates/userdata_dvm.yaml", {
    vm_user_name         = var.os_config.vm_user_name
    vm_user_displayname  = var.os_config.vm_user_displayname
    vm_user_password     = var.os_config.vm_user_password
    vm_user_ssh_key      = try(var.os_config.vm_user_ssh_key, "")
    hosts_content        = local.hosts_content
    dns_servers          = local.dns_servers_list
    cluster_node_ips     = local.cluster_node_ips
    inventory_content    = local.inventory_content
    cluster_vars_content = local.cluster_vars_content
    ansible_repo_url     = var.ansible.git_repo.repo_url
    ansible_repo_name    = var.ansible.git_repo.repo_name
    ansible_repo_branch  = var.ansible.git_repo.repo_branch
    ansible_playbook     = var.ansible.git_repo.playbook_name
    os_admin_username    = var.os_config.vm_user_name
    ansible_ssh_pass     = var.os_config.ansible_ssh_pass
    vault_secret         = var.ansible.vault_secret
  })

  # vCD Guest Customization scripts (initscript) for each VM type
  customization_master_script = [
    for i, node in local.master_nodes : templatefile("${path.module}/templates/customization_node.sh", {
      node_name           = node.name
      cloudinit_base64_gz = base64gzip(local.cloudinit_master_rendered)
    })
  ]

  customization_worker_script = [
    for i, node in local.worker_nodes : templatefile("${path.module}/templates/customization_node.sh", {
      node_name           = node.name
      cloudinit_base64_gz = base64gzip(local.cloudinit_worker_rendered)
    })
  ]

  customization_dvm_script = templatefile("${path.module}/templates/customization_node.sh", {
    node_name           = local.dvm_name
    cloudinit_base64_gz = base64gzip(local.cloudinit_dvm_rendered)
  })
}
