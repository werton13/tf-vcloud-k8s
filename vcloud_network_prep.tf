resource "vcd_vapp" "k8s_mgmt_vapp" {
  name = var.vapp_name
  metadata = {
    tag = "MGMT K8s"
   }   
}
resource "vcd_vapp_network" "k8s_mgmt_vapp_net" {
  org  = var.vcloud_orgname
  vdc  = var.vcloud_vdc

  depends_on         = [vcd_vapp.k8s_mgmt_vapp]
  name               = "${var.vapp_name}_vnet"
  vapp_name          = var.vapp_name
  gateway            = var.vcd_vapp_net_gw 
  netmask            = var.vcd_vapp_net_mask
  dns1               = var.vcd_vapp_net_dns1
  dns2               = var.vcd_vapp_net_dns2
  org_network_name   = var.vcloud_orgvnet

  static_ip_pool {
    start_address = var.static_ip_pool_start
    end_address   = var.static_ip_pool_end
  }

}
resource "vcd_vapp_static_routing" "k8s_mgmt_vapp_net_static_routing" {
  vapp_id    = vcd_vapp.k8s_mgmt_vapp.id
  network_id = vcd_vapp_network.k8s_mgmt_vapp_net.id
  enabled    = true

  #rule {
  #  name         = "rule1"
  #  network_cidr = "192.168.100.0/24"
  #  next_hop_ip  = "192.168.100.2"
  #}

}
resource "vcd_vapp_firewall_rules" "k8s_mgmt_vapp_net_fw" {
  vapp_id        = vcd_vapp.k8s_mgmt_vapp.id
  network_id     = vcd_vapp_network.k8s_mgmt_vapp_net.id
  default_action = "drop"

  rule {
    name             = var.fw_rule1_name
    policy           = var.fw_rule1_action
    protocol = ${var.fw_rule1_proto}
    destination_port = var.fw_rule1_dst_port
    destination_ip   = var.fw_rule1_dst_ip
    source_port      = var.fw_rule1_src_port
    source_ip        = var.fw_rule1_src_ip
    }
  
  rule {
    name             = var.fw_rule2_name
    policy           = var.fw_rule2_action
    protocol         = var.fw_rule2_proto
    destination_port = var.fw_rule2_dst_port
    destination_ip   = var.fw_rule2_dst_ip
    source_port      = var.fw_rule2_src_port
    source_ip        = var.fw_rule2_src_ip
    }  
  rule {
    name             = var.fw_rule3_name
    policy           = var.fw_rule3_action
    protocol         = var.fw_rule3_proto
    destination_port = var.fw_rule3_dst_port
    destination_ip   = var.fw_rule3_dst_ip
    source_port      = var.fw_rule3_src_port
    source_ip        = var.fw_rule3_src_ip
    }
  
}
resource "vcd_vapp_nat_rules" "k8s_mgmt_vapp_net_nat" {
  vapp_id    = vcd_vapp.k8s_mgmt_vapp.id
  network_id = vcd_vapp_network.k8s_mgmt_vapp_net.id
  nat_type   = "ipTranslation"
  enabled    = "false"

}