resource "vcd_vapp" "k8s_mgmt_vapp" {
  name = var.vcloud.vapp_name
  metadata = {
    tag = "MGMT K8s"
   }   
}

resource "vcd_vapp_org_network" "vappOrgNet" {
  depends_on  = [vcd_vapp.k8s_mgmt_vapp]
  org = var.vcloud.orgname
  vdc = var.vcloud.vdc
  vapp_name = var.vcloud.vapp_name
  org_network_name = var.vcloud.orgvnet_name
}

###----- configure load balancer for a Kubernetes API-server---------------------------------------------------------------

resource "vcd_edgegateway_settings" "egw-settings" {
  edge_gateway_id         = data.vcd_edgegateway.egw.id
  lb_enabled              = true
}

resource "vcd_lb_app_profile" "kube_api" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  enable_ssl_passthrough  = "true"
  persistence_mechanism   = "ssl-sessionid"

  name = "http-app-profile"
  type = "https"
}

resource "vcd_lb_app_profile" "ingress_http" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  enable_ssl_passthrough  = "false"
  persistence_mechanism   = "sourceip"

  name = "ingress_http"
  type = "http"
}

resource "vcd_lb_service_monitor" "kube_api" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw

  name        = "kube_api"
  interval    = "10"
  timeout     = "15"
  max_retries = "3"
  type        = "https"
  expected    = "HTTP/1.0 200 OK"
  method      = "GET"
  url         = "/readyz"
  #send        = "{\"key\": \"value\"}"
  send        = "HTTP/2"
  receive     = "ok"
  #extension = {
  #  content-type = "application/json"
  #  linespan     = ""
  #}
}
resource "vcd_lb_service_monitor" "ingress_http" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw

  name        = "ingress_http"
  interval    = "10"
  timeout     = "15"
  max_retries = "3"
  type        = "http"
  expected    = "HTTP/1.1 200 OK"
  method      = "GET"
  url         = "/healthz"
  #send        = "{\"key\": \"value\"}"
  send        = "HTTP/1.1"
  receive     = ""
}

resource "vcd_lb_server_pool" "kube_api_lb_pool" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  depends_on  = [vcd_vapp.k8s_mgmt_vapp,
                 vcd_lb_service_monitor.kube_api]

  name                 = "kube_api"
  description          = "description"
  algorithm            = "round-robin"
  enable_transparency  = false
  monitor_id = vcd_lb_service_monitor.kube_api.id

    member {
    condition       = "enabled"
    #name            = "${var.vms.masters.pref}-01"  
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst-01"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr,tonumber(var.ip_plan.m_node))}" #"${split("/", var.vms.masters.ip_pool[0])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
    member {
    condition       = "drain"
    #name            = "${var.vms.masters.pref}-02"
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst-02"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr,(tonumber(var.ip_plan.m_node)+1))}" #"${split("/", var.vms.masters.ip_pool[1])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
    member {
    condition       = "drain"
    #name            = "${var.vms.masters.pref}-03"
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-mst-03"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr,(tonumber(var.ip_plan.m_node)+2))}" #"${split("/", var.vms.masters.ip_pool[2])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
  }


}
resource "vcd_lb_server_pool" "ingress_http_pool" {
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw
  depends_on  = [vcd_vapp.k8s_mgmt_vapp,
                 vcd_lb_service_monitor.kube_api]

  name                 = "ingress_http_pool"
  description          = "description"
  algorithm            = "round-robin"
  enable_transparency  = false
  monitor_id = vcd_lb_service_monitor.ingress_http.id
  
    member {
    condition       = "enabled"
    #name            = "${var.vms.workers.pref}-0"
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk-01"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.w_node) )}" #"${split("/", var.vms.workers.ip_pool[0])[0]}"
    port            = var.kubernetes.ingress.controller_nodeport_http
    monitor_port    = var.kubernetes.ingress.controller_nodeport_http
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
   
    member {
    condition       = "enabled"
    #name            = "${var.vms.workers.pref}-1"
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk-02"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr, (tonumber(var.ip_plan.w_node)+1) )}" #"${split("/", var.vms.workers.ip_pool[1])[0]}"
    port            = var.kubernetes.ingress.controller_nodeport_http
    monitor_port    = var.kubernetes.ingress.controller_nodeport_http
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
   
    member {
    condition       = "enabled"
    #name            = "${var.vms.workers.pref}-2"
    name            = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}-wrk-03"
    ip_address      = "${cidrhost(var.os_config.vm_ip_cidr, (tonumber(var.ip_plan.w_node)+2))}" #"${split("/", var.vms.workers.ip_pool[2])[0]}"
    port            = var.kubernetes.ingress.controller_nodeport_http
    monitor_port    = var.kubernetes.ingress.controller_nodeport_http
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
}

resource "vcd_lb_virtual_server" "kube_api_lb_vs" {
  depends_on    = [vcd_lb_server_pool.kube_api_lb_pool]
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw

  name       = "kube_api"
  #ip_address = data.vcd_edgegateway.mygw.default_external_network_ip
  #ip_address = var.kubernetes.cluster.controlPlane_Endpoint
  ip_address = "${cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.kubeapi_lb) )}"
  #protocol   = var.protocol
  protocol   = "https"
  port       = 6443

  server_pool_id = vcd_lb_server_pool.kube_api_lb_pool.id
  app_profile_id = vcd_lb_app_profile.kube_api.id
  #app_rule_ids   = [vcd_lb_app_rule.redirect.id]
}
resource "vcd_lb_virtual_server" "ingress_http" {
  depends_on    = [vcd_lb_server_pool.kube_api_lb_pool]
  org          = var.vcloud.orgname
  vdc          = var.vcloud.vdc
  edge_gateway = var.vcloud.edgegw

  name       = "ingress_http"
  #ip_address = data.vcd_edgegateway.mygw.default_external_network_ip
  #ip_address = var.kubernetes.ingress.lb_ip#!!!
  ip_address = "${cidrhost(var.os_config.vm_ip_cidr, tonumber(var.ip_plan.ingress_lb) )}"
  
  #protocol   = var.protocol
  protocol   = "http"
  port       = 80

  server_pool_id = vcd_lb_server_pool.ingress_http_pool.id
  app_profile_id = vcd_lb_app_profile.ingress_http.id
  #app_rule_ids   = [vcd_lb_app_rule.redirect.id]
}






