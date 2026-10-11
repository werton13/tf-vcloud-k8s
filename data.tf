data "vcd_catalog" "vcd_dp_linux" {
  org  = var.vcloud.catalog_org != "" ? var.vcloud.catalog_org : var.vcloud.orgname
  name = var.vcloud.catalogname
}

data "vcd_edgegateway" "egw" {
  org  = var.vcloud.orgname
  vdc  = var.vcloud.vdc
  name = var.vcloud.edgegw
}

data "vcd_nsxt_alb_service_engine_group" "seg" {
  count = var.vcloud.network_type == "nsx-t" && var.vcloud.alb_service_engine_group != "" ? 1 : 0
  name  = var.vcloud.alb_service_engine_group
}