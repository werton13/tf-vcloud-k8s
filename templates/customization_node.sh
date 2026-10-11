#!/bin/bash
exec > /var/log/vcd-customization.log 2>&1
echo "=== [$(date)] Handing over initialization to Cloud-init for ${node_name} ==="

# 0. Configure network, default route, and DNS immediately via Netplan
cat << 'EOF_NET' > /etc/netplan/01-netplan.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${os_nic1_name}:
      dhcp4: false
      dhcp6: false
      addresses:
        - ${node_ip}/${cidr_prefix}
      routes:
        - to: default
          via: ${gateway_ip}
      nameservers:
        addresses: ${dns_servers_json}
EOF_NET
chmod 0600 /etc/netplan/01-netplan.yaml
rm -f /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
netplan apply 2>/dev/null || true
systemctl restart systemd-resolved 2>/dev/null || true

# 1. Prepare local NoCloud seed datasource for Cloud-init
mkdir -p /var/lib/cloud/seed/nocloud

cat << 'EOF_META' > /var/lib/cloud/seed/nocloud/meta-data
instance-id: ${node_name}
local-hostname: ${node_name}
EOF_META

cat << 'EOF_USER' | base64 -d | gunzip > /var/lib/cloud/seed/nocloud/user-data
${cloudinit_base64_gz}
EOF_USER

# 2. Trigger Cloud-init execution
cloud-init clean
cloud-init init
cloud-init modules --mode config
cloud-init modules --mode final

echo "=== [$(date)] Cloud-init initialization completed for ${node_name} ==="
exit 0

