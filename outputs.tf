output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = "${var.project.owner_org}-${var.project.name}-${var.project.env_name}"
}

output "kubernetes_version" {
  description = "Target Kubernetes version tag and full semantic version"
  value = {
    tag     = var.kubernetes.cluster.version
    version = local.target_version.short
  }
}

output "network_type" {
  description = "Active network and load balancer type in vCloud Director"
  value       = var.vcloud.network_type
}

output "kubeapi_endpoint" {
  description = "Kubernetes API Server VIP (internal)"
  value       = "https://${local.kubeapi_vip}:6443"
}

output "ingress_endpoint" {
  description = "Ingress Controller VIP (internal)"
  value       = local.ingress_vip
}

output "dvm_ip" {
  description = "Deployment VM IP address"
  value       = local.dvm_ip
}

output "master_nodes" {
  description = "List of Kubernetes master nodes and their IPs"
  value       = local.master_nodes
}

output "worker_nodes" {
  description = "List of Kubernetes worker nodes and their IPs"
  value       = local.worker_nodes
}

output "ssh_connect_to_dvm" {
  description = "Command to connect to the DVM host via SSH"
  value       = local.dvm_ssh_cmd
}

output "dvm_ansible_log_command" {
  description = "Command to follow Ansible bootstrap logs on the DVM"
  value       = "${local.dvm_ssh_cmd} 'tail -f /var/log/ansible-bootstrap.log'"
}

output "public_ip" {
  description = "Public IP address on Edge Gateway (auto-detected on NSX-V; kubernetes.vip.public_ip on NSX-T)"
  value       = local.egw_public_ip
}

output "public_kubeapi_endpoint" {
  description = "Public Kubernetes API endpoint reachable from Internet"
  value       = local.use_kube_vip ? "https://${local.egw_public_ip}:${var.kubernetes.vip.public_port_kubeapi}" : "https://${local.egw_public_ip}:6443"
}

output "public_ingress_endpoint" {
  description = "Public Ingress HTTP endpoint reachable from Internet"
  value       = local.use_kube_vip ? "http://${local.egw_public_ip}:${var.kubernetes.vip.public_port_ingress_http}" : "http://${local.egw_public_ip}:80"
}
