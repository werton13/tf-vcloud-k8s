#!/bin/bash
exec > /var/log/vcd-customization.log 2>&1
echo "=== [$(date)] Handing over initialization to Cloud-init for ${node_name} ==="

# 0. Configure network interface immediately so cloud-init and APT have connectivity
ip addr add ${node_ip}/${cidr_prefix} dev ${os_nic1_name} 2>/dev/null || true
ip link set ${os_nic1_name} up 2>/dev/null || true
ip route add default via ${gateway_ip} dev ${os_nic1_name} 2>/dev/null || true

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

