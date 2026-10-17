# ==============================================================================
# Shared vApp for Kubernetes nodes
# The vCloud CSI driver looks up node VMs inside a single vApp (vcloud-csi-config: vAppName),
# so all master and worker VMs are placed into one vApp. No vApp network is created:
# the existing Org VDC network is only attached (bridged) to the vApp.
# ==============================================================================

resource "vcd_vapp" "k8s_vapp" {
  name        = var.vcloud.vapp_name
  description = "Kubernetes cluster ${var.project.owner_org}-${var.project.name}-${var.project.env_name} nodes"
}

resource "vcd_vapp_org_network" "k8s_vapp_orgnet" {
  vapp_name        = vcd_vapp.k8s_vapp.name
  org_network_name = var.vcloud.orgvnet_name
  # VCD 10.4.1+ refuses to detach a network from a powered-on vApp (409 "Stop the vApp and try again"),
  # which breaks `terraform destroy`; let the provider power the vApp off before removal
  reboot_vapp_on_removal = true
}

# ==============================================================================
# NSX-V Load Balancer Resources (applied when var.vcloud.network_type == "nsx-v")
# ==============================================================================

resource "vcd_edgegateway_settings" "egw_settings" {
  count           = var.vcloud.network_type == "nsx-v" ? 1 : 0
  edge_gateway_id = data.vcd_edgegateway.egw[0].id
  lb_enabled      = true
}

resource "vcd_lb_app_profile" "kube_api" {
  count                  = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org                    = var.vcloud.orgname
  vdc                    = var.vcloud.vdc
  edge_gateway           = var.vcloud.edgegw
  enable_ssl_passthrough = true
  persistence_mechanism  = "ssl-sessionid"
  name                   = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-profile"
  type                   = "https"
}

resource "vcd_lb_app_profile" "ingress_http" {
  count                  = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org                    = var.vcloud.orgname
  vdc                    = var.vcloud.vdc
  edge_gateway           = var.vcloud.edgegw
  enable_ssl_passthrough = false
  persistence_mechanism  = "sourceip"
  name                   = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-http-profile"
  type                   = "http"
}

resource "vcd_lb_service_monitor" "kube_api" {
  count        = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  name         = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-mon"
  interval     = "10"
  timeout      = "15"
  max_retries  = "3"
  type         = "https"
  expected     = "HTTP/1.0 200 OK"
  method       = "GET"
  url          = "/readyz"
  send         = "HTTP/2"
  receive      = "ok"
}

resource "vcd_lb_service_monitor" "ingress_http" {
  count        = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  name         = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-mon"
  interval     = "10"
  timeout      = "15"
  max_retries  = "3"
  type         = "http"
  expected     = "HTTP/1.1 200 OK"
  method       = "GET"
  url          = "/healthz"
  send         = "HTTP/1.1"
  receive      = ""
}

resource "vcd_lb_server_pool" "kube_api_lb_pool" {
  count               = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org                 = var.vcloud.orgname
  vdc                 = var.vcloud.vdc
  edge_gateway        = var.vcloud.edgegw
  name                = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-pool"
  description         = "Kubernetes control plane API load balancer pool"
  algorithm           = "round-robin"
  enable_transparency = false
  monitor_id          = vcd_lb_service_monitor.kube_api[0].id

  dynamic "member" {
    for_each = local.master_nodes
    content {
      condition       = "enabled"
      name            = member.value.name
      ip_address      = member.value.ip
      port            = 6443
      monitor_port    = 6443
      weight          = 1
      min_connections = 0
      max_connections = 100
    }
  }
}

resource "vcd_lb_server_pool" "ingress_http_pool" {
  count               = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org                 = var.vcloud.orgname
  vdc                 = var.vcloud.vdc
  edge_gateway        = var.vcloud.edgegw
  name                = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-pool"
  description         = "Kubernetes Ingress HTTP load balancer pool"
  algorithm           = "round-robin"
  enable_transparency = false
  monitor_id          = vcd_lb_service_monitor.ingress_http[0].id

  dynamic "member" {
    for_each = local.worker_nodes
    content {
      condition       = "enabled"
      name            = member.value.name
      ip_address      = member.value.ip
      port            = tonumber(var.kubernetes.ingress.controller_nodeport_http)
      monitor_port    = tonumber(var.kubernetes.ingress.controller_nodeport_http)
      weight          = 1
      min_connections = 0
      max_connections = 100
    }
  }
}

resource "vcd_lb_virtual_server" "kube_api_lb_vs" {
  count          = var.vcloud.network_type == "nsx-v" ? 1 : 0
  depends_on     = [vcd_lb_server_pool.kube_api_lb_pool]
  org            = var.vcloud.orgname
  vdc            = var.vcloud.vdc
  edge_gateway   = var.vcloud.edgegw
  name           = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-vs"
  ip_address     = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb))
  protocol       = "https"
  port           = 6443
  server_pool_id = vcd_lb_server_pool.kube_api_lb_pool[0].id
  app_profile_id = vcd_lb_app_profile.kube_api[0].id
}

resource "vcd_lb_virtual_server" "ingress_http" {
  count          = var.vcloud.network_type == "nsx-v" ? 1 : 0
  depends_on     = [vcd_lb_server_pool.ingress_http_pool]
  org            = var.vcloud.orgname
  vdc            = var.vcloud.vdc
  edge_gateway   = var.vcloud.edgegw
  name           = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-http-vs"
  ip_address     = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.ingress_lb))
  protocol       = "http"
  port           = 80
  server_pool_id = vcd_lb_server_pool.ingress_http_pool[0].id
  app_profile_id = vcd_lb_app_profile.ingress_http[0].id
}

# ==============================================================================
# NSX-V NAT Rules (automatically applied when var.vcloud.network_type == "nsx-v")
# ==============================================================================

# Outbound SNAT for cluster network (enables Internet access for apt, docker, git)
resource "vcd_nsxv_snat" "k8s_outbound" {
  count              = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org                = var.vcloud.orgname
  vdc                = var.vcloud.vdc
  edge_gateway       = var.vcloud.edgegw
  network_type       = "ext"
  network_name       = local.egw_ext_net_name
  original_address   = var.os_config.vm_ip_cidr
  translated_address = local.egw_public_ip
  description        = "Outbound SNAT for K8s cluster (${var.project.owner_org}-${var.project.name}-${var.project.env_name})"
}

# Inbound DNAT for KubeAPI access from Internet/External network
resource "vcd_nsxv_dnat" "kubeapi_inbound" {
  count              = var.vcloud.network_type == "nsx-v" ? 1 : 0
  depends_on         = [vcd_lb_virtual_server.kube_api_lb_vs]
  org                = var.vcloud.orgname
  vdc                = var.vcloud.vdc
  edge_gateway       = var.vcloud.edgegw
  network_type       = "ext"
  network_name       = local.egw_ext_net_name
  original_address   = local.egw_public_ip
  original_port      = "6443"
  translated_address = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb))
  translated_port    = "6443"
  protocol           = "tcp"
  description        = "Inbound DNAT for KubeAPI (${var.project.owner_org}-${var.project.name}-${var.project.env_name})"
}

# Inbound DNAT for Ingress HTTP access from Internet/External network
resource "vcd_nsxv_dnat" "ingress_http_inbound" {
  count              = var.vcloud.network_type == "nsx-v" ? 1 : 0
  depends_on         = [vcd_lb_virtual_server.ingress_http]
  org                = var.vcloud.orgname
  vdc                = var.vcloud.vdc
  edge_gateway       = var.vcloud.edgegw
  network_type       = "ext"
  network_name       = local.egw_ext_net_name
  original_address   = local.egw_public_ip
  original_port      = "80"
  translated_address = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.ingress_lb))
  translated_port    = "80"
  protocol           = "tcp"
  description        = "Inbound DNAT for Ingress HTTP (${var.project.owner_org}-${var.project.name}-${var.project.env_name})"
}

# ==============================================================================
# NSX-T NAT Rules (applied when var.vcloud.network_type == "nsx-t")
# No load balancer on the Edge: kube-api and ingress VIPs are announced by kube-vip
# (ARP) from the masters. Only rules created here are managed; other rules on the
# shared Edge are left untouched. firewall_match = BYPASS lets NAT traffic pass the
# Edge gateway firewall (default deny) without touching its rule list:
# vcd_nsxt_firewall would own the whole list, including rules created outside this project.
# ==============================================================================

# Internal ports of DNAT targets (DNAT translates only the address; the internal port comes from the profile)
resource "vcd_nsxt_app_port_profile" "nat" {
  for_each   = var.vcloud.network_type == "nsx-t" ? local.nsxt_dnat_rules : {}
  org        = var.vcloud.orgname
  context_id = data.vcd_org_vdc.vdc.id
  scope      = "TENANT"
  name       = "${local.nsxt_rule_prefix}-${each.key}-tcp${each.value.internal_port}"

  app_port {
    protocol = "TCP"
    port     = [each.value.internal_port]
  }
}

resource "vcd_nsxt_nat_rule" "dnat" {
  for_each            = var.vcloud.network_type == "nsx-t" ? local.nsxt_dnat_rules : {}
  org                 = var.vcloud.orgname
  edge_gateway_id     = data.vcd_nsxt_edgegateway.egw[0].id
  name                = "${local.nsxt_rule_prefix}-${each.key}-dnat"
  description         = "Inbound DNAT ${local.egw_public_ip}:${each.value.external_port} -> ${each.value.internal_ip}:${each.value.internal_port} (managed by Terraform)"
  rule_type           = "DNAT"
  external_address    = local.egw_public_ip
  dnat_external_port  = each.value.external_port
  internal_address    = each.value.internal_ip
  app_port_profile_id = vcd_nsxt_app_port_profile.nat[each.key].id
  firewall_match      = "BYPASS"
  priority            = 100
}

# Outbound SNAT for the cluster network (apt, container registries, git). Lower precedence than the
# existing NO_SNAT rules (priority 0), so traffic to private interconnects keeps its original source.
resource "vcd_nsxt_nat_rule" "snat" {
  count            = var.vcloud.network_type == "nsx-t" ? 1 : 0
  org              = var.vcloud.orgname
  edge_gateway_id  = data.vcd_nsxt_edgegateway.egw[0].id
  name             = "${local.nsxt_rule_prefix}-snat"
  description      = "Outbound SNAT ${var.os_config.vm_ip_cidr} -> ${local.egw_public_ip} (managed by Terraform)"
  rule_type        = "SNAT"
  external_address = local.egw_public_ip
  internal_address = var.os_config.vm_ip_cidr
  firewall_match   = "BYPASS"
  priority         = 100
}
