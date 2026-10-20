## Kubernetes Cluster Deployment on VMware Cloud Director (vCD)

### Overview

Модуль предназначен для автоматизированного развертывания отказоустойчивого кластера Kubernetes внутри тенанта VMware Cloud Director с использованием публичного доступа в интернет.

Проект поддерживает **Kubernetes v1.35**, базовую ОС **Ubuntu 24.04 LTS (Noble Numbat)**, а также работу с обоими типами сетевой виртуализации: **NSX-V** (Edge Gateway LB) и **NSX-T** (kube-vip + Edge NAT).

#### Структура проекта

```text
.
├── versions.tf               # Требования к версиям Terraform и vcd провайдера
├── variables.tf              # Входные переменные проекта
├── main.tf                   # ВМ (DVM, Masters, Workers) и дополнительные диски
├── vcloud_network_prep.tf    # vApp Org Network, NSX-V Edge LB, NSX-T SNAT/DNAT
├── locals.tf                 # Расчет IP-плана, генерация inventory и переменных
├── outputs.tf                # Экспорт эндпоинтов, IP и SSH-команд
├── example.tfvars            # Пример конфигурации
└── templates/
    ├── userdata_dvm.yaml     # Cloud-init конфигурация DVM (генерация inventory и автостарт)
    ├── userdata_m.yaml       # Cloud-init конфигурация Master-нод
    └── userdata_w.yaml       # Cloud-init конфигурация Worker-нод
```

<details>
<summary><b>Архитектура и возможности</b></summary>

- **Узлы кластера:**
  - Control Plane (Master-ноды): от 1 до $N$ узлов (по умолчанию 3).
  - Data Plane (Worker-ноды): от 1 до $N$ узлов.
  - Deployment Workstation (DVM): служебная ВМ для оркестрации и выполнения Ansible.
- **Балансировка нагрузки (KubeAPI & Ingress):**
  - **NSX-V:** Нативный Edge Gateway Load Balancer (`vcd_lb_*`) с динамическими пулами участников.
  - **NSX-T:** без Edge Load Balancer. VIP KubeAPI и Ingress анонсирует [kube-vip](https://kube-vip.io) в ARP-режиме со static pod на master-нодах. Edge Gateway выполняет только SNAT/DNAT (`vcd_nsxt_nat_rule`); правила создаются с `firewall_match = BYPASS` и не затрагивают другие правила на общем Edge.
- **Конфигурация дисков:**
  - Системный диск OS Disk (paravirtual).
  - Опциональные дополнительные диски LVM под `/var` и `/var/lib` (containerd, etcd, kubelet) с автоматическим graceful fallback при их отсутствии.
- **Kubernetes 1.35 Стек:**
  - Официальный публичный репозиторий: `pkgs.k8s.io`.
  - Спецификация Kubeadm: `kubeadm.k8s.io/v1beta4`.
  - Container Runtime: `containerd` с `SystemdCgroup = true` и `registry.k8s.io/pause:3.10`.
  - Режим KubeProxy: `ipvs`.
  - Надежный нативный join через `kubeadm token create --print-join-command` и `--certificate-key`.
- **Addons & Observability:**
  - **CNI:** Calico Tigera Operator (`v1.36` / Calico `v3.29+`).
  - **CSI:** VMware Cloud Director Named Disk CSI Driver (`v1.5.0+`) с автоматическим CoreDNS hosts patch для vCloud API.
  - **Ingress:** NGINX Ingress Controller (публичный Helm-чарт).
  - **Metrics:** Kubernetes Metrics Server (публичный Helm-чарт).
  - **Monitoring:** Стек VictoriaMetrics (`vmoperator`, `vmagent` с поддержкой `remoteWrite`, `node-exporter`, `x509-certificate-exporter`, `vmservicescrapes`).
  - **Backup:** Автоматическое резервное копирование etcd-снимков на DVM-хост.

</details>

<details>
<summary><b>VIP и публичные порты (NSX-T)</b></summary>

Для `network_type = "nsx-t"` модуль **не создаёт Edge Load Balancer**. VIP KubeAPI
и Ingress анонсируются kube-vip со static pod на master-нодах, а Edge Gateway
выполняет только SNAT/DNAT. Все параметры находятся в `kubernetes.vip`:

| Параметр | По умолчанию | Обязателен | Описание |
|---|---:|---:|---|
| `kubernetes.vip.public_ip` | — | да (NSX-T) | Публичный IP Edge Gateway для DNAT. На Edge с IP Spaces адрес не определяется автоматически. |
| `kubernetes.vip.public_port_kubeapi` | `"6443"` | нет | Публичный порт DNAT на KubeAPI VIP:6443. |
| `kubernetes.vip.public_port_ingress_http` | `"80"` | нет | Публичный порт DNAT на Ingress VIP:80. |
| `kubernetes.vip.public_port_dvm_ssh` | `""` | нет | Публичный порт DNAT на DVM:22. Пустое значение = правило не создаётся. |
| `kubernetes.vip.kube_vip_enabled` | `true` | нет | Включает kube-vip для KubeAPI и Ingress VIP. Для NSX-T должен быть `true`, если не используется внешний LB. |
| `kubernetes.vip.kube_vip_version` | `"v0.8.10"` | нет | Тег образа kube-vip. |
| `kubernetes.vip.kube_vip_address` | `""` | нет | По умолчанию вычисляется из `ip_plan.kubeapi_lb` (`cidrhost`) и равен `k8s_controlPlane_Endpoint`. Если задан, должен совпадать. |
| `kubernetes.vip.ingress_lb_ip` | `""` | нет | По умолчанию вычисляется из `ip_plan.ingress_lb` (`cidrhost`). Если задан, должен совпадать. |
| `kubernetes.vip.k8s_api_extra_sans` | `[]` | нет | Дополнительные SAN для API-сертификата. `public_ip` добавляется автоматически. |

Пример для NSX-T:

```hcl
vcloud = {
  # ...
  network_type = "nsx-t"
}

kubernetes = {
  # ...
  vip = {
    public_ip                = "203.0.113.10"
    public_port_kubeapi      = "6443"
    public_port_ingress_http = "80"
    public_port_dvm_ssh      = "42768" # или "" — без правила
    kube_vip_version         = "v0.8.10"
    k8s_api_extra_sans       = ["k8s.example.com"]
  }
}
```

Для NSX-T Ansible-ветка должна поддерживать kube-vip:
`ansible.git_repo.repo_branch = "dev-r3-nsxt"`. По умолчанию используется `dev` —
ветка, в которой есть роль `k8s_addons_node_controller`.

> [!NOTE]
> **NSX-T: ALB больше не используется.**
> Параметр `vcloud.alb_service_engine_group` удалён. Для `network_type = "nsx-t"`
> задайте `kubernetes.vip.public_ip`; VIP KubeAPI и Ingress будут подняты kube-vip.
> Для NSX-V поведение не изменилось: используется Edge Gateway LB.

</details>

<details>
<summary><b>Опциональный контроллер масштабирования worker-нод (vcd-k8s-node-controller)</b></summary>

> [!WARNING]
> **Enabling `node_controller` transfers cluster ownership away from Terraform.**
> Once `node_controller.enabled = true`, the `vcd-k8s-node-controller` owns worker
> scaling and worker LB pool membership. Do **not** use `terraform apply` to change
> worker count, node configuration, or LB membership afterwards. Terraform is only
> responsible for the initial bootstrap. Use the `K8sWorkerPool` CRD (`kubectl`)
> instead. You must also set
> `node_controller.acknowledge_terraform_ownership_loss = true`.
>
> **Включение `node_controller` передаёт управление кластером контроллеру.**
> После `node_controller.enabled = true` масштабированием worker-нод и составом
> worker LB pool управляет `vcd-k8s-node-controller`. Не используйте
> `terraform apply` для изменения количества worker-нод, конфигурации нод или
> состава LB pool — используйте CRD `K8sWorkerPool`. Обязательно установите
> `node_controller.acknowledge_terraform_ownership_loss = true`.

Модуль может передать управление worker-нодами отдельному контроллеру
[`vcd-k8s-node-controller`](https://github.com/werton13/vcd-k8s-node-controller).
По умолчанию контроллер **выключен** (`node_controller.enabled = false`).

Минимальное включение в `terraform.tfvars` (все остальные параметры имеют
значения по умолчанию в `variables.tf`):

```hcl
node_controller = {
  enabled                              = true
  acknowledge_terraform_ownership_loss = true
  vcd_user                             = "vcd-node-controller-svc"
  vcd_password                         = "***"
}
```

Параметры `namespace`, `release_name`, `chart_repo`, `chart_name`,
`chart_version`, `image_repository`, `image_tag`, `image_pull_policy`,
`create_namespace`, `create_vcd_secret`, `vcd_secret_name`, `vcd_insecure`,
`helm_timeout`, `helm_atomic` и `create_pool` имеют значения по умолчанию.
Переопределяйте их только при необходимости (например, если чарт опубликован в
другом репозитории).

Terraform передаёт эти значения в Ansible через `cluster_vars_content`
(`/etc/k8s_cluster_vars.yaml` на DVM) с префиксом `node_controller_`. Ansible
playbook должен:

1. Создать namespace (если `node_controller_create_namespace = true`).
2. Создать Secret `node_controller_vcd_secret_name` с ключами `url`, `user`,
   `password`, `org`, `vdc`, `insecure` (если
   `node_controller_create_vcd_secret = true`).
3. Установить Helm-чарт `node_controller_chart_name` версии
   `node_controller_chart_version` из `node_controller_chart_repo` в namespace
   `node_controller_namespace` с release name `node_controller_release_name`,
   передав `image.repository`, `image.tag`, `image.pullPolicy` и
   `vcd.existingSecret`.
4. Создать объект `K8sWorkerPool` (если `node_controller_create_pool = true`)
   в namespace `default`, когда worker-ноды уже установлены: `replicas` =
   `vms_config.workers.vm_count`, `namePrefix` = имя кластера, остальные поля
   (`bootstrap`, `flavor`, `vcd`, `ipPlan`, `ingressPool`) — из
   `cluster_vars_content` (`node_controller_pool_*`). Существующий пул не
   изменяется, чтобы повторный `terraform apply` не сбрасывал ручное
   масштабирование через CRD.

Перед включением опубликуйте Helm-чарт (или укажите `chart_repo` на OCI-репозиторий)
и создайте сервисный аккаунт vCD с правами на VM и LB pool. Не используйте
admin-учётную запись в production.

Откат: контроллер не возвращает ownership автоматически. Чтобы снова управлять
worker-нодами через Terraform, нужно сначала выключить контроллер, привести
worker-ноды в нужное состояние и выровнять/импортировать Terraform state. Это
отдельная ручная процедура.

</details>

<details>
<summary><b>Требования к окружению vCloud</b></summary>

1. **Routed Network (Org VDC Network):**
   - Тип: Routed (подключена к Edge Gateway).
   - Подсеть CIDR (например, `192.168.100.0/24`).
   - Настроен SNAT для исходящего доступа нод в интернет.
   - Настроен Firewall (разрешен исходящий трафик в интернет и входящий трафик к VIP KubeAPI и Ingress).
2. **Шаблон ВМ в каталоге:**
   - Образ `Ubuntu 24.04 LTS` (или `22.04 LTS`) с установленным `cloud-init` и включенным UUID (`disk.EnableUUID = TRUE`).
3. **Сервисный аккаунт для CSI:**
   - Пользователь vCD с правами на управление Named Disks в VDC.
4. **Для NSX-T (при выборе network_type = "nsx-t"):**
   - Публичный IP Edge Gateway задаётся в `kubernetes.vip.public_ip`: на Edge с IP Spaces адрес по умолчанию не определяется.
   - VIP `ip_plan.kubeapi_lb` и `ip_plan.ingress_lb` должны быть свободны и находиться в подсети кластера.
   - kube-vip работает в ARP-режиме: master-ноды и VIP должны быть в одном L2-сегменте.
   - Ansible-ветка с kube-vip: `ansible.git_repo.repo_branch = "dev-r3-nsxt"`.
   - SNAT/DNAT и firewall вручную настраивать не нужно; модуль создаёт NAT-правила с `firewall_match = BYPASS`.

</details>

### Быстрый старт

1. Создайте отдельный Terraform-проект и скопируйте в него `variables.tf` и пример `tfvars`:

   ```bash
   mkdir tf-vcloud-k8s-deploy && cd tf-vcloud-k8s-deploy
   git clone --depth 1 --branch dev https://github.com/werton13/tf-vcloud-k8s.git /tmp/tf-vcloud-k8s
   cp /tmp/tf-vcloud-k8s/variables.tf .
   cp /tmp/tf-vcloud-k8s/example.tfvars terraform.tfvars
   ```

2. Создайте `main.tf`:

   ```hcl
   terraform {
     required_version = ">= 1.5.0, < 2.0.0"

     required_providers {
       vcd = {
         source  = "vmware/vcd"
         version = ">= 3.13.0, < 4.0.0"
       }
     }
   }

   module "vcloud-k8s-cluster" {
     source = "github.com/werton13/tf-vcloud-k8s?ref=dev" # for production, pin a tag or commit

     project         = var.project
     vcloud          = var.vcloud
     ip_plan         = var.ip_plan
     vms_config      = var.vms_config
     disks_config    = var.disks_config
     os_config       = var.os_config
     ansible         = var.ansible
     kubernetes      = var.kubernetes
     versions        = var.versions
     obs_config      = var.obs_config
     node_controller = var.node_controller
   }
   ```

3. Отредактируйте `terraform.tfvars` — он создан из `example.tfvars`, который содержит пример всех доступных параметров. Для NSX-T раскомментируйте блок `kubernetes.vip`, задайте `public_ip` и установите `ansible.git_repo.repo_branch = "dev-r3-nsxt"`. Для NSX-V оставьте ветку по умолчанию `dev` (в ней есть роль `k8s_addons_node_controller`).

4. Инициализируйте и запустите Terraform:

   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

5. Отслеживание развертывания:
   Terraform выведет удобные команды в `outputs`:

   ```bash
   # Подключение к DVM (для NSX-T с public_port_dvm_ssh используйте output ssh_connect_to_dvm):
   ssh k8sadmin@<DVM_IP>

   # Просмотр логов bootstrap кластера:
   ssh k8sadmin@<DVM_IP> 'tail -f /var/log/ansible-bootstrap.log'
   ```
