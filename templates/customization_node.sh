#!/bin/bash
exec > /var/log/vcd-customization.log 2>&1
echo "=== [$(date)] Configuring the network for ${node_name} ==="

# Configure the static address, default route and DNS before cloud-init's
# package stage needs the network.
#
# cloud-init is deliberately NOT started from here: the guest already gets its
# user-data through the OVF datasource (guestinfo.userdata, set as a guest
# property by the module), and the image's own cloud-init services execute it
# exactly once. Seeding a second copy and calling cloud-init by hand created a
# second, concurrent final stage: it skipped the still-running package module
# and went straight to scripts_user (runcmd), so the starter ran before
# ansible was installed.
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

echo "=== [$(date)] Network configured for ${node_name}; cloud-init runs from its own units ==="
exit 0
