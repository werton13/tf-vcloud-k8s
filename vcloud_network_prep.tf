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
resource "vcd_lb_virtual_server" "kube_api" {
  org          = var.vcloud_orgname
  vdc          = var.vcloud_vdc
  edge_gateway = var.vcloud_edgegw

  name       = "kube_api"
  #ip_address = data.vcd_edgegateway.mygw.default_external_network_ip
  ip_address = var.k8s_controlPlane_Endpoint
  #protocol   = var.protocol
  protocol   = "https"
  port       = 6443

  server_pool_id = vcd_lb_server_pool.kube_api.id
  #app_profile_id = vcd_lb_app_profile.http.id
  #app_rule_ids   = [vcd_lb_app_rule.redirect.id]
}


#resource "vcd_lb_service_monitor" "monitor" {
#  org          = var.org
#  vdc          = var.vdc
#  edge_gateway = var.edge_gateway
#
#  name        = "http-monitor"
#  interval    = "5"
#  timeout     = "20"
#  max_retries = "3"
#  type        = var.protocol
#  method      = "GET"
#  url         = "/health"
#  send        = "{\"key\": \"value\"}"
#  extension = {
#    content-type = "application/json"
#    linespan     = ""
#  }
#}


resource "vcd_lb_server_pool" "kube_api" {
  org          = var.org
  vdc          = var.vdc
  edge_gateway = var.edge_gateway

  name                 = "kube_api"
  description          = "description"
  algorithm            = "httpheader"
  algorithm_parameters = "headerName=host"
  enable_transparency  = true

    member {
    condition       = "enabled"
    name            = "${var.vms.masters.pref}-0"
    ip_address      = data.template_file.cloudinit_dvm.master0_ip
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
  }
    member {
    condition       = "drain"
    name            = "${var.vms.masters.pref}-1"
    ip_address      = data.template_file.cloudinit_dvm.master1_ip
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
  }
    member {
    condition       = "drain"
    name            = "${var.vms.masters.pref}-2"
    ip_address      = data.template_file.cloudinit_dvm.master2_ip
    port            = 6443
    monitor_port    = 6443
    weight          = 1
    min_connections = 0
    max_connections = 100
  }


}