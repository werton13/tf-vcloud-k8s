variable env_type {
  type        = string
  default     = "public"
  description = "can be private or public"
}

variable "vcloud" {
    type = object({
        server_fqdn          = string # vcloud_url
        server_ip            = string # vcloud_ip
        allow_unverified_ssl = string #vcloud_allow_unverified_ssl default     = "true"
        max_retry_timeout    = string #vcloud_max_retry_timeout    default     = "240"
        vdc           = string #vcloud_vdc 
        orgname       = string #vcloud_orgname
        admin                = string #vcloud_user 
        admin_pwd            = string #vcloud_password 
        csi_svc              = string #vcloud_csiadmin_username        
        csi_svc_pwd          = string #vcloud_csiadmin_password
        vapp_name            = string
        catalogname   = string #vcloud_catalogname 
        vm_template_name     = string #vcloud_vmtmplname 
        orgvnet_name         = string #vcloud_orgvnet
        edgegw               = string #vcloud_edgegw
    })
}

variable "vms" {
    type = map(object({
        pref = string
        vm_cpu_count = string
        vm_ram_size  = string
        vm_disk_size = string
        vm_count = string
  #     ip_pool = list(string)
    }))
}

variable "os_config" {
    type = object({
        vm_user_name        = string  #vm_user_name os_admin_username
        vm_user_password    = string  #vm_user_password
        ansible_ssh_pass    = string  # ansible_ssh_pass
        vm_user_displayname = string  #vm_user_displayname
        vm_user_ssh_key     = string  #vm_user_ssh_key"
 #      vm_ipv4_gw          = string # to deprecate
        vm_ip_cidr          = string
 #       vm_dns_server       = string #not used
        def_dns             = string
        env_dns1            = string
        env_dns2            = string
        ntp_srv1            = string
        ntp_srv2            = string        
        ubuntu_animal_code  = string
        docker_mirror       = string
#        containerd_mirror   = string
        os_nic1_name        = string
    })
}

#System disk vars
variable "system_disk_bus" {
  description = ""
  default     = "default"
}

variable "system_disk_size" {
  description = ""
  default     = "default"
}

variable "system_disk_storage_profile" {
  description = ""
  default     = "default"
}

#Additional disks vars
variable "add_disks" {
  type = map(object({
    sizegb          = string
    bus_num         = string
    unit_num        = string
    storage_profile = string
    bus_type        = string
  }))
  default = {
          diskm1 = {
            sizegb = "10"
            bus_num = "1"
            unit_num = "0"
            storage_profile = ""
            bus_type = "paravirtual" 
          }
          diskm2 = {
            sizegb = "30"
            bus_num = "1"
            unit_num = "1"
            storage_profile = ""
            bus_type = "paravirtual"  
          }
          diskw1 = {
            sizegb = "10"
            bus_num = "1"
            unit_num = "0"
            storage_profile = ""
            bus_type = "paravirtual" 
          }
          diskw2 = {
            sizegb = "30"
            bus_num = "1"
            unit_num = "1"
            storage_profile = ""
            bus_type = "paravirtual"  
          }
 }
}

variable "ansible" {
    type = object({
        git_repo = object({
          repo_url      = string
          repo_name     = string 
          repo_branch   = string
          playbook_name = string  #ansible_playbook
#          access_token  = string     
        }        
        )
    })
}

variable "kubernetes" {
    type = object({

        cluster = object({
          version                       = string
          cluster_name                  = string #same as cluster_id
          controlPlane_Endpoint         = string #k8s_controlPlane_Endpoint
        })

        cni = object({
          svc_subnet                    = string #k8s_service_subnet
          pod_subnet                    = string #k8s_pod_subnet
          calico_network_cidr_blocksize = string #calico_network_cidr_blocksize
         }        
        )

        pvc = object({
          sc_storage_policy_name  = string #sc_storage_policy_name
          sc_name                 = string #sc_name
         }        
        )

        ingress = object({
          controller_nodeport_http  = string 
          controller_nodeport_https = string
          ext_fqdn                  = string #ingress_ext_fqdn
         }        
        )

    })
}

variable "versions" {
    type = object({
        v1_28 = object({

            short      = string  #k8s_version_short
            full       = string  #k8s_ver
            containerd = string
            cri-tools  = string

            cni = object({
              calico_version = string  #calico_version
              tigera_version = string 
              calicoctl_url  = string
             }        
            )

            csi = object({
              driver_version = string # vsphere_csi_driver_version
              cpi_tag        = string 
              cpi_url        = string
             }        
            )

            etcd = object({
              ETCD_RELEASES_URL = string 
              etcd_ver          = string 
             }        
            )

            helm = object({
              helm_repo_path       = string 
              helm_version         = string 
             }        
            )
        }        
        )
    })
}

variable "vmagent_config" {
    type = object({

        remoteWriteUrl        = string
        remoteWriteUsername   = string
        remoteWritePassword   = string
        etcdProxyMainImageURL = string
        etcdProxyInitImageURL = string
        env_name              = string
        dctr_name             = string
        project_name          = string

    })
}
