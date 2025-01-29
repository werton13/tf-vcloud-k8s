
project = {
  owner_org = "" # or example myorg
  name      = "" # or example xapi
  env_name  = "" # for example one of the: dev/stage/prod
}

vcloud = {
    server_fqdn          = "https://my_vcloud_web_portal_url/api"
    server_ip            = "my_vcloud_web_portal IP address" #just get this from reverse DNS lookup
    allow_unverified_ssl = "true" #default 
    max_retry_timeout    = "240"  #default
    vdc                  = "My-VDC-name" #should be provided by vcloud provider 
    orgname              = "My_orgname"  #should be provided by vcloud provider
    admin                = "My_vcloud_admin_username" #should be provided by vcloud provider 
    admin_pwd            = "My_vcloud_admin_password" #should be provided by vcloud provider 
    csi_svc              = "vcloud_username_for_csi" #shoud be precreated and verified    
    csi_svc_pwd          = "cloud_password_for_csi"  #shoud be precreated and verified 
    vapp_name            = "my_vapp_name" # creating during this code execution
    catalogname          = "my_vcloud_catalogue_name" #shoud be precreated
    vm_template_name     = "ubuntu22.04-uuid-enabled-v1" #shoud be precreated and preconfigured
    orgvnet_name         = "my_vcloud_org_vnet_name" #shoud be precreated and configured according desired IP plan
    edgegw               = "my_vcloud_edgegw"        #should be provided by vcloud provider
}

# do not add this into yor tfvars file until you want to change default IP distribution
ip_plan = {
  m_node     = "4"  # first master node IP will be x.x.x.4
  w_node     = "7"  # first worker node IP will be x.x.x.7
  dvm        = "-3" # DVM IP will be -3 from the end of subnet - i.e. 192.168.0.253 for 192.168.0.0/24
  kubeapi_lb = "2"  #  will be x.x.x.2 # this IP will be assigned for the KubeAPI load balancer virtual server in the vcloud edge server configuration
  ingress_lb = "3"  #  will be x.x.x.3
}

vms_config = {
    dvm = {
      vm_cpu_count = "2"
      vm_ram_size  = "4096"
      vm_count = "1"
    }
    masters = {
      vm_cpu_count = "2"
      vm_ram_size  = "4096"
      vm_count = "3"
    },
    workers = {
      vm_cpu_count = "2"
      vm_ram_size  = "8192"
      vm_count = "2"
    }
}

disks_config = {
          osdisk = { #/dev/sda1  mounted --> /
            sizegb = "20"   #system_disk_size
            bus_num  = "0"  #system_disk_bus
            unit_num = "0"
            storage_profile = "" #system_disk_storage_profile
            bus_type = "paravirtual"
          }
          diskm1 = {  # this disk used for creating volume group and lv with mount: /dev/mapper/data1_vg-data1_lv  --> /var on the master nodes
            sizegb = "10"
            bus_num = "1"
            unit_num = "0"
            storage_profile = ""
            bus_type = "paravirtual" 
          }
          diskm2 = { # this disk used for creating volume group and lv with mount: /dev/mapper/data2_vg-data2_lv  --> /var/lib /var on the master nodes
            sizegb = "30"
            bus_num = "1"
            unit_num = "1"
            storage_profile = ""
            bus_type = "paravirtual"  
          }
          diskw1 = { # this disk used for creating volume group and lv with mount: /dev/mapper/data1_vg-data1_lv  --> /var on the worker nodes
            sizegb = "10"
            bus_num = "1"
            unit_num = "0"
            storage_profile = ""
            bus_type = "paravirtual" 
          }
          diskw2 = { # this disk used for creating volume group and lv with mount: /dev/mapper/data2_vg-data2_lv  --> /var/lib /var on the worker nodes
            sizegb = "30"
            bus_num = "1"
            unit_num = "1"
            storage_profile = ""
            bus_type = "paravirtual"  
          }
}

os_config = {
  vm_user_name  = "k8cluster_admin_user_name" # will be created
  vm_user_displayname = "cluster admin"
  vm_user_password = "$6$rounds=----."         # mkpasswd  --method=SHA-512 --rounds=4096 somesecretpassword
  ansible_ssh_pass = "somesecretpasswordhere"  # should match  vm_user_password in plain text
  vm_user_ssh_key  = "ssh-ed25519 somessh pub key here" # ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "john@example.com" 
  vm_ip_cidr       = "192.168.100.0/24" #desired IP network (should be preconfigured in vcloudorgvnet_name)
  def_dns  = "8.8.8.8"     # dns server configured inside vm ip configuration
  env_dns1 = "77.88.8.8"   # dns servers,specific to environment - to replace default dns in ip configuration   
  env_dns2 = "77.88.8.1"   # dns servers,specific to environment - to replace default dns in ip configuration
  ubuntu_animal_code = "noble" # for example Jammy or noble - https://wiki.ubuntu.com/Releases # reserved for upcoming changes in cloudinit config, just skip it
  docker_mirror      = "mirror.gcr.io"
  #  containerd_mirror  = "containerd endpoint fqdn" # currently not used
  ntp_srv1 = "10.99.6.3"  # currently not used -under construction
  ntp_srv2 = "10.97.6.3"  # currently not used -under construction
  os_nic1_name = "ens192" # shoudl match expected naming in choosed disk template
}

ansible = {
  git_repo = {
    repo_url = "https://github.com/werton13/k8s-kubeadm-r2.git" # public ansible repository url on the gihub  - created to run from the DVM vm to coordinate cluster building
    repo_name =  "k8s-kubeadm-r2"                               # public ansible repository name on the gihub - created to run from the DVM vm to coordinate cluster building
    repo_branch = "dev-r2"                                      # public ansible repository branch on the gihub - created to run from the DVM vm to coordinate cluster building
    playbook_name = "main.yaml"                                 # ansible playbook name to run  from the public ansible repository - created to run from the DVM vm to coordinate cluster building
  }
}

kubernetes = {

  cluster = {
      version      = "v1_28"   #kubernetes version tag to choose  components versions set from the 'versions' variable --> defined below this block
    }

  cni = {
      svc_subnet = "10.96.9.0/12" #k8s_service_subnet
      pod_subnet = "10.244.9.0/22" #k8s_pod_subnet
      calico_network_cidr_blocksize = "26" #calico_network_cidr_blocksize
    }

  pvc = {
      sc_storage_policy_name = "SAS_DP" #sc_storage_policy_name
      sc_name = "ssd-default"       # your storage class name
    }
  
  ingress = {
      controller_nodeport_http  = "30888" #ingress_controller_nodeport_http
      controller_nodeport_https = "30443" #ingress_controller_nodeport_https
      ext_fqdn = ""
  }

}

versions = {
    v1_28 = {
      short = "1.28.15"     # k8s_version_short = "1.28.6"
      full  = "1.28.15-1.1" # k8s_ver = "1.28.6-1.1"
      containerd = ""
      cri-tools = ""
      cni = {
        calico_version = "v3.27.3"
        tigera_version = "v1.32.5" 
      }
      csi = {
        driver_version = "v3.0.2"
        cpi_tag = "v1.28.1"
        cpi_url = "" # could be used to define custom images url for CPI
      }
      etcd = {
        ETCD_RELEASES_URL = "" # could be used to define custom images url for CPI
        etcd_ver = "v3.5.12" 
      }
      helm = {
        helm_repo_path = "" # could be used to define custom images url for Helm
        helm_version = "v3.16.3"
      }
   }
} 

obs_config = {
    common = {
      obs_type = "none" # could be prom_stack/none (vm_stack in the future)
    }
    
    vm_stack = {              # reserved for the victoria metrics values
        type                  = "" #could be standalone/operator
        remoteWriteUrl        = "" #leave empty if obs_type = "none" or "prom_stack"  
        remoteWriteUsername   = "" #leave empty if obs_type = "none" or "prom_stack" 
        remoteWritePassword   = "" #leave empty if obs_type = "none" or "prom_stack" 
        etcdProxyMainImageURL = "" #leave empty if obs_type = "none" or "prom_stack" 
        etcdProxyInitImageURL = "" #leave empty if obs_type = "none" or "prom_stack" 
        label_env_name        = "" #leave empty if obs_type = "none" or "prom_stack" 
        label_dctr_name       = "" #leave empty if obs_type = "none" or "prom_stack" 
        label_project_name    = "" #leave empty if obs_type = "none" or "prom_stack" 
    }

    prom_stack = {
      prometheus = {
        param1   = ""  # reserved
        }
      alertmanager = {
        telegram_receiver_name = ""  # alertmgr_telegram_receiver_name
        telegram_bot_token     = ""  # alertmgr_telegram_bot_token
        telegram_chatid        = ""  # alertmgr_telegram_chatid
        # Go to this address and talk to BotFather to get a new bot.
        #  https://core.telegram.org/bots#6-botfather
        #
        # Take note of the Token
        # Create a channel and invite the bot to the channel
        #
        # The bot must be invited as admin.
        # Find the chat ID:
        #  after the bot is in the channel, type a message in the channel, then go to:
        #  https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates
        }
      grafana  = {
        param1 = "" # reserved
        }
    }
}



