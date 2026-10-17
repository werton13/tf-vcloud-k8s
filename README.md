## Kubernetes Cluster Deployment on VMware Cloud Director (vCD)

Модуль предназначен для автоматизированного развертывания отказоустойчивого кластера Kubernetes внутри тенанта VMware Cloud Director с использованием публичного доступа в интернет.

Проект поддерживает **Kubernetes v1.35**, базовую ОС **Ubuntu 24.04 LTS (Noble Numbat)**, а также работу с обоими типами сетевой виртуализации: **NSX-V** и современным **NSX-T ALB (Avi)**.

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

---

### Архитектура и возможности

- **Узлы кластера:**
  - Control Plane (Master-ноды): от 1 до $N$ узлов (по умолчанию 3).
  - Data Plane (Worker-ноды): от 1 до $N$ узлов.
  - Deployment Workstation (DVM): служебная ВМ для оркестрации и выполнения Ansible.
- **Балансировка нагрузки (KubeAPI & Ingress):**
  - **NSX-V:** Нативный Edge Gateway Load Balancer (`vcd_lb_*`) с динамическими пулами участников.
  - **NSX-T:** Нативный NSX-T Advanced Load Balancer (Avi ALB) через ресурсы `vcd_nsxt_alb_pool` и `vcd_nsxt_alb_virtual_service`.
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

---

### Опциональный контроллер масштабирования worker-нод (vcd-k8s-node-controller)

Модуль может передать управление worker-нодами отдельному контроллеру
[`vcd-k8s-node-controller`](https://github.com/werton13/vcd-k8s-node-controller).
По умолчанию контроллер **выключен** (`node_controller.enabled = false`).

**Важно:** после включения контроллера Terraform больше не управляет
масштабированием worker-нод и составом worker LB pool. Не выполняйте
`terraform apply` для изменения этих параметров — используйте CRD
`K8sWorkerPool`. Terraform отвечает только за первоначальный bootstrap.

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
`helm_timeout` и `helm_atomic` имеют значения по умолчанию. Переопределяйте их
только при необходимости (например, если чарт опубликован в другом репозитории).

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

Перед включением опубликуйте Helm-чарт (или укажите `chart_repo` на OCI-репозиторий)
и создайте сервисный аккаунт vCD с правами на VM и LB pool. Не используйте
admin-учётную запись в production.

Откат: контроллер не возвращает ownership автоматически. Чтобы снова управлять
worker-нодами через Terraform, нужно сначала выключить контроллер, привести
worker-ноды в нужное состояние и выровнять/импортировать Terraform state. Это
отдельная ручная процедура.

---

### Требования к окружению vCloud

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
   - На Edge Gateway должен быть назначен Service Engine Group (например, `Default-SEG`).

---

### Быстрый старт

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/werton13/tf-vcloud-k8s.git
   cd tf-vcloud-k8s
   ```

2. Скопируйте и настройте файл переменных:
   ```bash
   cp example.tfvars terraform.tfvars
   # Отредактируйте terraform.tfvars под ваши параметры vCloud
   ```

3. Инициализируйте и запустите Terraform:
   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. Отслеживание развертывания:
   Terraform выведет удобные команды в `outputs`:
   ```bash
   # Подключение к DVM:
   ssh k8sadmin@<DVM_IP>

   # Просмотр логов bootstrap кластера:
   ssh k8sadmin@<DVM_IP> 'tail -f /var/log/ansible-bootstrap.log'
   ```

---

### Структура проекта

```
.
├── versions.tf               # Требования к версиям Terraform и vcd провайдера
├── variables.tf              # Входные переменные проекта
├── main.tf                   # ВМ (DVM, Masters, Workers) и дополнительные диски
├── vcloud_network_prep.tf    # Настройка vApp Org Network и балансировщиков (NSX-V / NSX-T)
├── locals.tf                 # Расчет IP-плана, генерация inventory и переменных
├── outputs.tf                # Экспорт эндпоинтов, IP и SSH-команд
├── example.tfvars            # Пример конфигурации
└── templates/
    ├── userdata_dvm.yaml     # Cloud-init конфигурация DVM (генерация inventory и автостарт)
    ├── userdata_m.yaml       # Cloud-init конфигурация Master-нод
    └── userdata_w.yaml       # Cloud-init конфигурация Worker-нод
```