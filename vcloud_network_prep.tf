# ==============================================================================
# NSX-V Load Balancer Resources (applied when var.vcloud.network_type == "nsx-v")
# ==============================================================================

resource "vcd_edgegateway_settings" "egw_settings" {
  count           = var.vcloud.network_type == "nsx-v" ? 1 : 0
  edge_gateway_id = data.vcd_edgegateway.egw.id
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
# NSX-T ALB (Avi) Resources (applied when var.vcloud.network_type == "nsx-t")
# ==============================================================================

resource "vcd_nsxt_alb_pool" "kube_api" {
  count           = var.vcloud.network_type == "nsx-t" ? 1 : 0
  edge_gateway_id = data.vcd_edgegateway.egw.id
  name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-pool"
  algorithm       = "ROUND_ROBIN"
  default_port    = 6443

  dynamic "member" {
    for_each = local.master_nodes
    content {
      ip_address = member.value.ip
      port       = 6443
      ratio      = 1
      enabled    = true
    }
  }
}

resource "vcd_nsxt_alb_virtual_service" "kube_api" {
  count                    = var.vcloud.network_type == "nsx-t" ? 1 : 0
  edge_gateway_id          = data.vcd_edgegateway.egw.id
  name                     = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-kubeapi-vs"
  pool_id                  = vcd_nsxt_alb_pool.kube_api[0].id
  service_engine_group_id  = data.vcd_nsxt_alb_service_engine_group.seg[0].id
  virtual_ip_address       = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb))
  application_profile_type = "APPLICATION_PROFILE_L4"

  service_port {
    start_port = 6443
    type       = "TCP_PROXY"
  }
}

resource "vcd_nsxt_alb_pool" "ingress_http" {
  count           = var.vcloud.network_type == "nsx-t" ? 1 : 0
  edge_gateway_id = data.vcd_edgegateway.egw.id
  name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-http-pool"
  algorithm       = "ROUND_ROBIN"
  default_port    = tonumber(var.kubernetes.ingress.controller_nodeport_http)

  dynamic "member" {
    for_each = local.worker_nodes
    content {
      ip_address = member.value.ip
      port       = tonumber(var.kubernetes.ingress.controller_nodeport_http)
      ratio      = 1
      enabled    = true
    }
  }
}

resource "vcd_nsxt_alb_virtual_service" "ingress_http" {
  count                    = var.vcloud.network_type == "nsx-t" ? 1 : 0
  edge_gateway_id          = data.vcd_edgegateway.egw.id
  name                     = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-ingress-http-vs"
  pool_id                  = vcd_nsxt_alb_pool.ingress_http[0].id
  service_engine_group_id  = data.vcd_nsxt_alb_service_engine_group.seg[0].id
  virtual_ip_address       = cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.ingress_lb))
  application_profile_type = "APPLICATION_PROFILE_HTTP"

  service_port {
    start_port = 80
    type       = "TCP_PROXY"
  }
}
