## Kubernetes cluster deployment on a VMware vCloud platform

This module intended to deploy Kubernetes cluster inside a tenant on standard VMware vCloud platform.
It is creating set of virtual machines for K8s control and data plane, make their preparation, bootstrap Kubernetes cluster, add all defined members and install a set of Kubernetes addons.

All customusation and configuration performing by a dedicated Ansible playbook: https://github.com/werton13/k8s-kubeadm-ansible.git which is created specifically for this project and hardcoded into module as default value.

Ansible playbook run from a first master node.

Currently the following list of Kubernetes addons installing:


  - Tigera operator for Calico CNI: https://docs.tigera.io/calico/3.25/about
  - vCloud CSI driver: https://github.com/vmware/cloud-director-named-disk-csi-driver
  - Kubernetes metrics server: https://github.com/kubernetes-sigs/metrics-server
  - Prometheus Monitoring Community: https://github.com/prometheus-community
    * Prometheus alerting rules defined (under construction)
    * Alert Manager config with Telegram integration
  - Grafana Labs Grafana: https://github.com/grafana
    * Preconfigured for Prometheus source
    * Preinstalled the following dashboards:
      + Node Exporter Full: https://grafana.com/grafana/dashboards/1860-node-exporter-full/
      + kube-state-metrics-v2: https://grafana.com/grafana/dashboards/13332-kube-state-metrics-v2/
      + Prometheus Stats: https://grafana.com/grafana/dashboards/358-prometheus-stats/
  - Ingress NGINX Controller:  https://kubernetes.github.io/ingress-nginx/


#### HOW TO USE:

<b>To use this module you have to:
  - copy variables file from this repo
  - create terraform.tfvars file from example file in thi repo
  - fill provider block and specify required variables as in the example below</b>


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
  source = "github.com/werton13/tf-vcloud-k8s?ref=dev"

  vcloud_url                 = var.vcloud_url
  vcloud_ip                  = var.vcloud_ip
  vcloud_vdc                 = var.vcloud_vdc
  vcloud_orgname             = var.vcloud_orgname
  vcloud_user                = var.vcloud_user
  vcloud_password            = var.vcloud_password
  vcloud_csiadmin_username   = var.vcloud_csiadmin_username
  vcloud_csiadmin_password   = var.vcloud_csiadmin_password
  vapp_name                  = var.vapp_name
  vcloud_catalogname         = var.vcloud_catalogname
  vcloud_vmtmplname          = var.vcloud_vmtmplname
  vcloud_orgvnet             = var.vcloud_orgvnet
  vcloud_edgegw              = var.vcloud_edgegw

  vm_user_name               = var.vm_user_name
  vm_user_password           = var.vm_user_password
  vm_user_displayname        = var.vm_user_displayname
  vm_user_ssh_key            = var.vm_user_ssh_key

  ansible_ssh_pass           = var.ansible_ssh_pass
  ansible_repo_url           = var.ansible_repo_url
  ansible_repo_branch        = var.ansible_repo_branch
  ansible_repo_name          = var.ansible_repo_name

  k8s_cluster_name           = var.k8s_cluster_name
  k8s_controlPlane_Endpoint  = var.k8s_controlPlane_Endpoint
  k8s_cluster_id             = var.k8s_cluster_id
  ingress_lb_ip              = var.ingress_lb_ip
  sc_storage_policy_name     = var.sc_storage_policy_name
  sc_name                    = var.sc_name
  ingress_ext_fqdn           = var.ingress_ext_fqdn
  ingress_controller_nodeport_http  = var.ingress_controller_nodeport_http
  ingress_controller_nodeport_https = var.ingress_controller_nodeport_https
  os_nic1_name               = var.os_nic1_name


  alertmgr_telegram_receiver_name = var.alertmgr_telegram_receiver_name
  alertmgr_telegram_bot_token     = var.alertmgr_telegram_bot_token
  alertmgr_telegram_chatid        = var.alertmgr_telegram_chatid

  vms = var.vms

  tenant_cluster_ro_rolename = var.tenant_cluster_ro_rolename
  tenant_ns_default          = var.tenant_ns_default
  tenant_k8s_admin_username  = var.tenant_k8s_admin_username
  tenant_orgname             = var.tenant_orgname
  tenant_orgname_orgunit     = var.tenant_orgname_orgunit
  tenant_emailaddress        = var.tenant_emailaddress
  certificate_validity       = var.certificate_validity
  
  add_disks        = var.add_disks
  system_disk_bus  = var.system_disk_bus
  system_disk_size = var.system_disk_size
  
  k8s_ver           = var.k8s_ver  
  k8s_version_short = var.k8s_version_short
  calico_version    = var.calico_version

  def_dns  = var.def_dns
  env_dns1 = var.env_dns1
  env_dns2 = var.env_dns2
}

```
<details>
  <summary><b>Default values</b></summary>

```
lbvm_count = "0"  
vcloud_allow_unverified_ssl = "true"
vcloud_max_retry_timeout    = "240"
vms = {
    masters = {
      pref = "k8s-m"
      vm_cpu_count = "2"
      vm_ram_size  = "4096"
      vm_disk_size = "40"
      vm_count = "1"
      ip_pool =  ["192.168.100.110",
                  "192.168.100.111"]
    },
    workers = {
      pref = "k8s-w"
      vm_cpu_count = "4"
      vm_ram_size  = "8192"
      vm_disk_size = "40"
      vm_count = "3"
      ip_pool =  ["192.168.100.114",
                  "192.168.100.115",
                  "192.168.100.116"]

    }
}
ansible_repo_url  = "https://github.com/werton13/k8s-kubeadm-ansible.git"
ansible_repo_name = "k8s-kubeadm-ansible"
ansible_playbook  = "main.yaml"
os_admin_username = "kuberadm"

k8s_ver           = "1.22.17-00"
k8s_version_short = "1.22.0"
calico_version    = "v3.25.0"

k8s_service_subnet = "10.96.0.0/12"
k8s_pod_subnet     = "10.244.0.0/22"
calico_network_cidr_blocksize = "26"
```

  
</details>