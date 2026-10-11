terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = ">= 3.8.0, < 4.0.0"
    }
  }
}
