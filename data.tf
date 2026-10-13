data "vcd_catalog" "vcd_dp_linux" {
  org  = var.vcloud.catalog_org != "" ? var.vcloud.catalog_org : var.vcloud.orgname
  name = var.vcloud.catalogname
}

data "vcd_org_vdc" "vdc" {
  org  = var.vcloud.orgname
  name = var.vcloud.vdc
}

# NSX-V Edge Gateway (load balancer and NAT on the Edge)
data "vcd_edgegateway" "egw" {
  count = var.vcloud.network_type == "nsx-v" ? 1 : 0
  org   = var.vcloud.orgname
  vdc   = var.vcloud.vdc
  name  = var.vcloud.edgegw
}

# NSX-T Edge Gateway (NAT only; VIPs are served by kube-vip inside the cluster)
data "vcd_nsxt_edgegateway" "egw" {
  count    = var.vcloud.network_type == "nsx-t" ? 1 : 0
  org      = var.vcloud.orgname
  owner_id = data.vcd_org_vdc.vdc.id
  name     = var.vcloud.edgegw
}
