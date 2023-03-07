*HOW TO USE*: To use this module you have to fill provider block and specify required variables as in example below:


```hcl
provider "vcd" {
  user                 = var.vcloud_user
  password             = var.vcloud_password
  org                  = var.vcloud_orgname
  vdc                  = var.vcloud_vdc
  url                  = var.vcloud_url
  allow_unverified_ssl = var.vcloud_allow_unverified_ssl
  max_retry_timeout    = var.vcloud_max_retry_timeout
}

module "vcloud-k8s-cluster" {
  source = "github.com/werton13/tf-vcloud-k8s"

  vcloud_url                 = var.vcloud_url
  vcloud_vdc                 = var.vcloud_vdc
  vcloud_orgname             = var.vcloud_orgname
  vcloud_user                = var.vcloud_user
  vcloud_password            = var.vcloud_password
  vapp_name                  = var.vapp_name
  vcloud_catalogname         = var.vcloud_catalogname
  vcloud_vmtmplname          = var.vcloud_vmtmplname
  vcloud_orgvnet             = var.vcloud_orgvnet

  vm_user_name               = var.vm_user_name
  vm_user_password           = var.vm_user_password
  vm_user_displayname        = var.vm_user_displayname
  vm_user_ssh_key            = var.vm_user_ssh_key

  ansible_ssh_pass           = var.ansible_ssh_pass

  k8s_controlPlane_Endpoint  = var.k8s_controlPlane_Endpoint
  k8s_cluster_id             = var.k8s_cluster_id
  sc_storage_policy_name     = var.sc_storage_policy_name
  sc_name                    = var.sc_name
  ingress_ext_fqdn           = var.ingress_ext_fqdn
  os_nic1_name               = var.os_nic1_name

  alertmgr_telegram_receiver_name = var.alertmgr_telegram_receiver_name
  alertmgr_telegram_bot_token     = var.alertmgr_telegram_bot_token
  alertmgr_telegram_chatid        = var.alertmgr_telegram_chatid
}

```