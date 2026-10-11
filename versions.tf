terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = ">= 3.13.0, < 4.0.0" # set_extra_config (disk.EnableUUID) requires 3.13+
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
}

provider "vcd" {
  user                 = var.vcloud.admin
  password             = var.vcloud.admin_pwd
  org                  = var.vcloud.orgname
  vdc                  = var.vcloud.vdc
  url                  = var.vcloud.server_fqdn
  max_retry_timeout    = var.vcloud.max_retry_timeout
  allow_unverified_ssl = var.vcloud.allow_unverified_ssl
}
