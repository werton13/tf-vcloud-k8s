project = {
  owner_org = "myorg"
  name      = "k8s-cluster"
  env_name  = "prod"
}

vcloud = {
  server_fqdn          = "https://vcloud.example.com/api"
  server_ip            = "192.168.1.10" # IP address of vCloud API endpoint
  allow_unverified_ssl = "true"
  max_retry_timeout    = "240"
  vdc                  = "My-VDC-Name"
  orgname              = "My-Org-Name"
  admin                = "vcloud_admin_user"
  admin_pwd            = "vcloud_admin_password"
  csi_svc              = "vcloud_csi_service_user"
  csi_svc_pwd          = "vcloud_csi_service_password"
  catalogname          = "Templates"
  catalog_org          = "" # Optional: specify if catalog belongs to another org (e.g. "MWS-Catalogs")
  vm_template_name     = "ubuntu24.04-uuid-enabled-v1"
  orgvnet_name         = "routed-k8s-net"
  vapp_name            = "mts-k8s-lab" # shared vApp for k8s nodes (required by vCloud CSI)
  edgegw               = "edge-gw-01"
  env_type             = "public"
  network_type         = "nsx-v" # "nsx-v": Edge Gateway LB + NAT; "nsx-t": kube-vip VIPs + Edge NAT
  # public_ip              = ""      # NSX-V only: optional public IP override; NSX-T uses kubernetes.vip.public_ip
}

ip_plan = {
  m_node       = "4"  # first master node IP will be x.x.x.4
  w_node       = "7"  # first worker node IP will be x.x.x.7
  dvm          = "-3" # DVM IP: third from the end of the subnet (192.168.100.253)
  kubeapi_lb   = "2"  # KubeAPI LB VIP (x.x.x.2)
  ingress_lb   = "3"  # Ingress LB VIP (x.x.x.3)
  vm_ip_offset = "0"  # addresses skipped at the start of the CIDR; same plan as the pool
}

vms_config = {
  dvm = {
    vm_cpu_count = "2"
    vm_ram_size  = "4096"
    vm_count     = "1"
  }
  masters = {
    vm_cpu_count = "2"
    vm_ram_size  = "4096"
    vm_count     = "3"
  }
  workers = {
    vm_cpu_count = "4"
    vm_ram_size  = "8192"
    vm_count     = "2"
  }
}

disks_config = {
  osdisk = {
    sizegb          = "40"
    bus_num         = "0"
    unit_num        = "0"
    storage_profile = ""
    bus_type        = "paravirtual"
  }
  diskm1 = { # Used for /var on master nodes (set sizegb = "0" to disable)
    sizegb          = "20"
    bus_num         = "1"
    unit_num        = "0"
    storage_profile = ""
    bus_type        = "paravirtual"
  }
  diskm2 = { # Used for /var/lib on master nodes
    sizegb          = "40"
    bus_num         = "1"
    unit_num        = "1"
    storage_profile = ""
    bus_type        = "paravirtual"
  }
  diskw1 = { # Used for /var on worker nodes
    sizegb          = "10"
    bus_num         = "1"
    unit_num        = "0"
    storage_profile = ""
    bus_type        = "paravirtual"
  }
  diskw2 = { # Used for /var/lib on worker nodes
    sizegb          = "30"
    bus_num         = "1"
    unit_num        = "1"
    storage_profile = ""
    bus_type        = "paravirtual"
  }
}

os_config = {
  vm_user_name        = "k8sadmin"
  vm_user_displayname = "Kubernetes Administrator"
  vm_user_password    = "$6$rounds=4096$rounds...hash" # mkpasswd --method=SHA-512 somesecret
  ansible_ssh_pass    = "somesecretpasswordhere"
  vm_user_ssh_key     = "" # Optional: paste public SSH key here (e.g. "ssh-ed25519 AAA...") or leave empty
  vm_ip_cidr          = "192.168.100.0/24"
  def_dns             = "8.8.8.8"
  env_dns1            = "8.8.8.8"
  env_dns2            = "1.1.1.1"
  env_dns3            = "1.0.0.1"
  ubuntu_animal_code  = "noble" # Ubuntu 24.04 LTS Noble Numbat
  # sshd AllowUsers. Omitted = "*@<vm_ip_cidr>" (the cluster nodes' subnet, which
  # is how the DVM reaches every node); state it only to replace the default.
  # allowed_ssh_ips = ["*@192.168.100.0/24"]
  os_nic1_name = "ens192"
}

ansible = {
  git_repo = {
    repo_url      = "https://github.com/werton13/k8s-kubeadm-r2.git"
    repo_name     = "k8s-kubeadm-r2"
    repo_branch   = "dev" # branch must carry the k8s_addons_node_controller role
    playbook_name = "main.yaml"
  }
  vault_secret = "your_vault_password_secret_here"
}

kubernetes = {
  cluster = {
    version = "v1_35"
  }
  cni = {
    svc_subnet                    = "10.96.0.0/12"
    pod_subnet                    = "10.244.0.0/16"
    calico_network_cidr_blocksize = "26"
  }
  pvc = {
    sc_storage_policy_name = "Standard-Storage"
    sc_name                = "vcloud-default"
  }
  ingress = {
    controller_nodeport_http  = "30888"
    controller_nodeport_https = "30443"
    ext_fqdn                  = ""
  }

  # NSX-T only. Ignored when vcloud.network_type = "nsx-v".
  # Uncomment this block and set public_ip when network_type = "nsx-t".
  # vip = {
  #   public_ip                = "203.0.113.10" # required on NSX-T
  #   public_port_kubeapi      = "6443"         # default
  #   public_port_ingress_http = "80"           # default
  #   public_port_dvm_ssh      = ""             # default: no SSH DNAT; e.g. "42768"
  #   kube_vip_enabled         = true           # default
  #   kube_vip_version         = "v0.8.10"      # default
  #   kube_vip_address         = ""             # computed = ip_plan.kubeapi_lb
  #   ingress_lb_ip            = ""             # computed = ip_plan.ingress_lb
  #   k8s_api_extra_sans       = ["k8s.example.com"] # default []
  # }
}

versions = {
  v1_35 = {
    short      = "1.35.9"
    full       = "1.35.9-1.1"
    containerd = "2.2.1-0ubuntu1~24.04.3" # full apt version (noble-updates)
    cri-tools  = "1.35.0-1.1"             # full apt version (pkgs.k8s.io)
    cni = {
      calico_version = "v3.31.5"
      tigera_version = "v1.40.8"
    }
    csi = {
      driver_version = "v1.5.0"
      cpi_tag        = "v1.35.0"
      cpi_url        = ""
    }
    etcd = {
      ETCD_RELEASES_URL = ""
      etcd_ver          = "v3.5.15"
    }
    helm = {
      helm_repo_path = ""
      helm_version   = "v3.16.3"
    }
  }
  v1_28 = {
    short      = "1.28.15"
    full       = "1.28.15-1.1"
    containerd = "1.7.13"
    cri-tools  = "1.28.0"
    cni = {
      calico_version = "v3.27.3"
      tigera_version = "v1.32.5"
    }
    csi = {
      driver_version = "v1.5.0"
      cpi_tag        = "v1.28.1"
      cpi_url        = ""
    }
    etcd = {
      ETCD_RELEASES_URL = ""
      etcd_ver          = "v3.5.12"
    }
    helm = {
      helm_repo_path = ""
      helm_version   = "v3.16.3"
    }
  }
}

obs_config = {
  common = {
    obs_type = "vm_stack" # vm_stack / prom_stack / none
  }
  vm_stack = {
    type                  = "operator"
    remoteWriteUrl        = "https://vmagent.example.com/api/v1/write"
    remoteWriteUsername   = ""
    remoteWritePassword   = ""
    etcdProxyMainImageURL = ""
    etcdProxyInitImageURL = ""
    label_env_name        = "prod"
    label_dctr_name       = "vcloud-dc1"
    label_project_name    = "k8s-cluster"
  }
  prom_stack = {
    prometheus = {
      param1 = ""
    }
    alertmanager = {
      telegram_receiver_name = ""
      telegram_bot_token     = ""
      telegram_chatid        = ""
    }
    grafana = {
      param1 = ""
    }
  }
}

# -----------------------------------------------------------------------------
# Optional: vcd-k8s-node-controller (worker autoscaling)
#
# WARNING: enabling this controller transfers ownership of worker scaling and
# worker LB pool membership from Terraform to the controller/CRD. After enabling,
# do NOT use terraform apply to change worker count, node configuration, or
# worker LB pool membership; use the K8sWorkerPool CRD instead.
#
# All other settings (namespace, release, chart, image, secret name, timeouts,
# etc.) have defaults in variables.tf and normally do not need editing.
# -----------------------------------------------------------------------------
node_controller = {
  enabled                              = false # install the nodescale worker controller
  acknowledge_terraform_ownership_loss = false # required with enabled = true

  namespace         = "vcd-nodescale-system"                                    # release namespace
  release_name      = "vcd-nodescale"                                           # helm release name
  chart_repo        = "https://k8s-nodescale.github.io/vcd-k8s-node-controller" # chart repository
  chart_name        = "vcd-nodescale"                                           # chart name
  chart_version     = "1.3.33"                                                  # chart version; keep in step with image_tag
  image_repository  = "docker.io/werton13/vcd-k8s-node-controller"              # controller image
  image_tag         = "1.3.33"                                                  # image tag; the same release as the chart
  image_pull_policy = "IfNotPresent"                                            # pull only when the tag is missing

  # The controller logs in with vcloud.admin / vcloud.admin_pwd - the account the
  # cluster is installed with - so no credentials are set here.
  create_vcd_secret = true              # create the Secret holding that account
  vcd_secret_name   = "vcd-credentials" # its name in the release namespace
  vcd_insecure      = true              # skip the vCD API certificate check

  create_namespace = true  # create the release namespace
  helm_timeout     = "10m" # wait this long for the release to become ready
  helm_atomic      = true  # roll the release back on failure
  create_pool      = true  # apply the K8sWorkerPool for the workers Terraform made

  # Placement: the control plane is the default because the pool must be able to
  # reach zero - the last-worker guard refuses to delete the node it runs on.
  replica_count       = 1                                                # controller replicas
  priority_class_name = "system-cluster-critical"                        # keeps it above the workloads it evicts
  node_selector       = { "node-role.kubernetes.io/control-plane" = "" } # where it runs
  tolerations = [{                                                       # tolerate the control-plane taint
    key      = "node-role.kubernetes.io/control-plane"
    operator = "Exists"
    effect   = "NoSchedule"
  }]
  affinity   = {} # extra affinity/podAntiAffinity
  dns_policy = "" # empty keeps cluster DNS; "Default" if CoreDNS cannot run on a master

  # Guest policy for the workers the controller creates (chart bootstrap.defaults);
  # a pool may override any of it in its own spec.bootstrap.
  bootstrap = {
    ntp_servers              = ["ntp1.example.com", "ntp2.example.com"]         # chrony sources in new workers
    apt_mirror               = ""                                               # empty keeps the image's sources
    sysctls                  = { "net.netfilter.nf_conntrack_max" = "2621440" } # sysctl.d entries
    kernel_modules           = ["nf_conntrack"]                                 # loaded before the sysctls
    containerd_sandbox_image = ""                                               # empty keeps the image's pause image
    ca_bundle_file           = ""                                               # PEM file trusted in the guests
    ssh_allowed_sources      = []                                               # extra sshd AllowUsers sources
  }

  # The management page: a second container in the same release, served through
  # the cluster's ingress on /nodescale-ui.
  ui = {
    enabled          = false               # deploy the page and its API
    ingress_enabled  = true                # publish it through the cluster ingress
    auth_enabled     = true                # the admin/viewer Secret
    auth_secret_name = "nodescale-ui-auth" # its name; created on first install
    admin_username   = "admin"             # account that may change the pool
    viewer_username  = "viewer"            # account that may only read it
  }
}
