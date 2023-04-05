resource "vcd_vapp" "k8s_mgmt_vapp" {
  name = var.vapp_name
  metadata = {
    tag = "MGMT K8s"
   }   
}

resource "vcd_vapp_org_network" "vappOrgNet" {
  depends_on  = [vcd_vapp.k8s_mgmt_vapp]
  org = var.vcloud_orgname
  vdc = var.vcloud_vdc
  vapp_name = var.vapp_name
  org_network_name = var.vcloud_orgvnet 
}

###----- configure load balancer for a Kubernetes API-server---------------------------------------------------------------
resource "vcd_lb_app_profile" "kube_api" {
  org          = var.vcloud_orgname
  vdc          = var.vcloud_vdc
  edge_gateway = var.vcloud_edgegw
  enable_ssl_passthrough  = "true"
  persistence_mechanism   = "ssl-sessionid"

  name = "http-app-profile"
  type = "https"
}

resource "vcd_lb_service_monitor" "kube_api" {
  org          = var.vcloud_orgname
  vdc          = var.vcloud_vdc
  edge_gateway = var.vcloud_edgegw

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

resource "vcd_lb_server_pool" "kube_api_lb_pool" {
  org          = var.vcloud_orgname
  vdc          = var.vcloud_vdc
  edge_gateway = var.vcloud_edgegw
  depends_on  = [vcd_vapp.k8s_mgmt_vapp,
                 vcd_lb_service_monitor.kube_api]

  name                 = "kube_api"
  description          = "description"
  algorithm            = "round-robin" #ip-hash, round-robin, uri, leastconn, url, or httpheader
  #algorithm_parameters = "headerName=host"
  enable_transparency  = false
  monitor_id = vcd_lb_service_monitor.kube_api.id

    member {
    condition       = "enabled"
    name            = "${var.vms.masters.pref}-0"
    ip_address      = "${split("/", var.vms.masters.ip_pool[0])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
    member {
    condition       = "drain"
    name            = "${var.vms.masters.pref}-1"
    ip_address      = "${split("/", var.vms.masters.ip_pool[1])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
   }
    member {
    condition       = "drain"
    name            = "${var.vms.masters.pref}-2"
    ip_address      = "${split("/", var.vms.masters.ip_pool[2])[0]}"
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
  }


}

resource "vcd_lb_virtual_server" "kube_api_lb_vs" {
  depends_on    = [vcd_lb_server_pool.kube_api_lb_pool]
  org          = var.vcloud_orgname
  vdc          = var.vcloud_vdc
  edge_gateway = var.vcloud_edgegw

  name       = "kube_api"
  #ip_address = data.vcd_edgegateway.mygw.default_external_network_ip
  ip_address = var.k8s_controlPlane_Endpoint
  #protocol   = var.protocol
  protocol   = "https"
  port       = 6443

  server_pool_id = vcd_lb_server_pool.kube_api_lb_pool.id
  app_profile_id = vcd_lb_app_profile.kube_api.id
  #app_rule_ids   = [vcd_lb_app_rule.redirect.id]
}




