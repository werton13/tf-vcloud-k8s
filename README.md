## Kubernetes cluster deployment on a VMware vCloud platform

This module intended to deploy Kubernetes cluster inside a tenant on standard VMware vCloud platform.
It  creates a set of virtual machines for K8s control and data plane, make their preparation, bootstrap Kubernetes cluster, add all defined members and install a set of Kubernetes addons.

All customusation and configuration performing by a dedicated Ansible playbook: https://github.com/werton13/k8s-kubeadm-ansible.git which was  created specifically for this project(and for the parallel vsphere project) and embedded into module variable.

Ansible playbook runs from the dedicated DVM virtual machine, deployed as part of thic code execution.

Currently the following list of Kubernetes addons installing:


  - Tigera operator for Calico CNI: https://docs.tigera.io/calico/3.25/about
  - vCloud CSI driver: https://github.com/vmware/cloud-director-named-disk-csi-driver
  - Kubernetes metrics server: https://github.com/kubernetes-sigs/metrics-server
  - Ingress NGINX Controller:  https://kubernetes.github.io/ingress-nginx/
  - Monitoring stack - allow to chose from 2 options - none/Prometheus stack/(third option victoria monitoring - under construction)
    - Prometheus Monitoring Community: https://github.com/prometheus-community
    * Prometheus alerting rules defined (under construction)
    * Alert Manager config with Telegram integration
    - Grafana Labs Grafana: https://github.com/grafana
      * Preconfigured for Prometheus source
      * Preinstalled the following dashboards:
        + Node Exporter Full: https://grafana.com/grafana/dashboards/1860-node-exporter-full/
        + kube-state-metrics-v2: https://grafana.com/grafana/dashboards/13332-kube-state-metrics-v2/
        + Prometheus Stats: https://grafana.com/grafana/dashboards/358-prometheus-stats/


#### WHAT IT WILL DO:

During this terraform code execution will be perormed:
 - creation a set of virtual machines for:
   - 3 master nodes - default
   - n worker nodes - as many as defined in input variables
   - 1 DVM host - to run ansible code and coordinate it execution on master and worker nodes
 - create and assign a set of additional disks for master and worker nodes with sizes, configured in input variables
 - install all required packages and do required OS configuration in preparation for Kubernetes cluster bootstraping
 - install all required Kubernetes packajes
 - bootstrap Kubernetes cluster with network configuration defined in the input variables
 - install and configure Calico CNI in the operator approach
 - install and configure vCloud CSI from this project: https://github.com/vmware/cloud-director-named-disk-csi-driver/tree/main
 - install metrics server, ingress controller and optionally monitoring stack with Telegram integration
 - configure DVM host as cluster manager workstation with all required tools (like kubectl, helm and bash modifocations )
 - copy kubernetes kubeconfig file to the DVM host into cluster admin home catalogue
 - configure a scheduled automatic etcd backup on each master node, receiving and storing  those files on the DVM host
 


#### HOW TO USE:

<b>To use this module you have to: </b>

- Prepare vCloud configuration:
  - precreate virtual network
    * scope: Organization Virtual Data Center
    * type: routed
    * gateway CIDR: - according desired IP plan
    * DNS: - server IP with internet names resolution available
  - create SNAT rule to allow internet outbound connections from the created virtual network
  - create Firewall rule to allow internet outbound connections from the created virtual network
  - create Firewall rule to allow  connections from  created virtual network to the IP of LoadBalancer VIP which will be assigned to KubeAPI LoadBalancer
  - enable LoadBalancer in the vcloud edge Load Balancer global configuration
  - create service account for vcloud CSI https://github.com/vmware/cloud-director-named-disk-csi-driver/tree/main
  - create storage policy, which will be assigned for Kubernetes storage class 
- create new terraform project
- copy variables.tf file from this repository into your new project
- copy example.tfvars and modify it according your environment
- create main.tf file and fill it the following way:


```hcl
provider "vcd" {
  user                 = var.vcloud.admin
  password             = var.vcloud.admin_pwd
  org                  = var.vcloud.orgname
  vdc                  = var.vcloud.vdc
  url                  = var.vcloud.server_fqdn
  allow_unverified_ssl = var.vcloud.allow_unverified_ssl
  max_retry_timeout    = var.vcloud.max_retry_timeout
}

module "vcloud-k8s-cluster" {
  source = "github.com/werton13/tf-vcloud-k8s?ref=dev-r2"

  vcloud       = var.vcloud
  vms          = var.vms
  disks_config = var.disks_config
  os_config    = var.os_config
  ansible      = var.ansible
  kubernetes   = var.kubernetes
  versions     = var.versions
  obs_config   = var.obs_config

}

```
<details>
  <summary><b>Default values</b></summary>

```  
vcloud_allow_unverified_ssl = "true"
vcloud_max_retry_timeout    = "240"
under construction ...
```
 
</details>