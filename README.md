## Kubernetes Cluster Deployment on VMware Cloud Director (vCD)

Модуль предназначен для автоматизированного развертывания отказоустойчивого кластера Kubernetes внутри тенанта VMware Cloud Director с использованием публичного доступа в интернет.

Проект поддерживает **Kubernetes v1.35**, базовую ОС **Ubuntu 24.04 LTS (Noble Numbat)**, а также работу с обоими типами сетевой виртуализации: **NSX-V** и **NSX-T**.

---

### Архитектура и возможности

- **Узлы кластера:**
  - Control Plane (Master-ноды): от 1 до $N$ узлов (по умолчанию 3).
  - Data Plane (Worker-ноды): от 1 до $N$ узлов.
  - Deployment Workstation (DVM): служебная ВМ для оркестрации и выполнения Ansible.
- **Балансировка нагрузки (KubeAPI & Ingress):**
  - **NSX-V:** Нативный Edge Gateway Load Balancer (`vcd_lb_*`) с динамическими пулами участников.
  - **NSX-T:** без балансировщика на Edge (ALB не требуется). VIP kube-api и VIP ingress (Service `LoadBalancer`) анонсирует [kube-vip](https://kube-vip.io) в ARP-режиме со static pod на master-нодах. Edge Gateway выполняет только NAT: SNAT сети кластера и DNAT `public_ip:<порт>` на VIP и DVM (`vcd_nsxt_nat_rule`). Правила NAT создаются с `firewall_match = BYPASS`, поэтому список правил firewall Edge не меняется, а другие правила NAT на общем Edge не затрагиваются.
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
   - Публичный IP Edge Gateway (`vcloud.public_ip`) задаётся явно: на Edge с IP Spaces адрес по умолчанию не определяется. Можно использовать IP, на котором уже есть чужие правила, если порты не пересекаются.
   - VIP (`ip_plan.kubeapi_lb`, `ip_plan.ingress_lb`) не должны быть заняты; лучше выбрать их вне static pool сети.
   - SNAT, DNAT и firewall вручную настраивать не нужно.
   - Ansible-ветка с поддержкой kube-vip: `ansible.git_repo.repo_branch`.

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