# project_issues — DVM bootstrap failures in the vCD/Kubernetes test environment

**Tag:** 2026-10-21T19:56Z (UTC)
**Repo:** werton13/tf-vcloud-k8s, branch dev, commits b9d7a4a then 887ca0a
**Environment:** tf-vcloud-test-dev_2026 (vCD, NSX-V, cluster KION-WEB-DEV)

## Core sense (read this first)

Our bootstrap is the standard cloud-init scenario — install packages, then run a
script — and cloud-init guarantees that order: `packages:` is executed by the
final-stage module `package_update_upgrade_install`, and `runcmd:` is executed by
`scripts_user` strictly after it.

The failures never came from that pattern. They came from three local factors
that were stacked on top of it:

1. a **second driver** for cloud-init (the vCD guest-customization initscript
   called `cloud-init clean/init/modules --mode config/final` by hand while systemd ran
   the same stages);
2. **vCD guest customization itself reboots the guest** ~1 minute after first
   boot (VMware DeployPkg, not cloud-init), and that reboot lands inside
   cloud-init's apt transaction;
3. this network has **no DHCP** (`dhcp_pool = []`), so a VM has no address unless the
   guest configures it itself — that is the only reason the customization
   initscript existed at all.

Fixing (1) alone exposed (2); fixing (2) is only possible by dropping vCD
customization, which is only possible if cloud-init brings the address up
itself before the package stage. That is what the current code does.

## 1. The standard pattern and its guarantee

| Step | Mechanism | Stage |
|---|---|---|
| address | `bootcmd:` -> write netplan, `netplan apply` | config (before packages) |
| packages | `packages:` -> cloud-init's own apt call | final |
| script | `runcmd:` -> `/ansible_starter.sh` | final, after packages |
| driver | systemd's cloud-init only | one boot |

`bootcmd` is the one deliberate deviation from the textbook variant: the more usual
`network:` block was not used because it could not be verified in this environment
(every attempt to test it was blocked by vCD customization, which was still
setting the address). `bootcmd` is a standard cloud-init key and runs before the
config and final stages, so the address is up before apt starts.

## 2. Why it broke — chronology of the three causes

### Cause 1: two drivers on one state machine (original failure)

The initscript wrote a NoCloud copy of the user-data and then ran

```
cloud-init clean
cloud-init init
cloud-init modules --mode config
cloud-init modules --mode final
```

while the image's own `cloud-init.service` / `cloud-config.service` /
`cloud-final.service` executed the same stages at boot.

cloud-init writes a module's "already ran" marker when the module **starts**.
The second final stage therefore skipped `package_update_upgrade_install` (still
running in the first process) and went straight to `scripts_user`, i.e. to runcmd.
On the DVM that executed `/ansible_starter.sh` before ansible existed, and the
starter died at its first `ansible-vault encrypt_string` with "command not found".

Log evidence: runcmd started 16:25:43, apt-get started 16:25:58.

Fix (commit b9d7a4a): remove the NoCloud seed, `cloud-init clean` and the manual
module calls; let the image's cloud-init run once.

### Cause 2: vCD customization reboots the guest mid-apt

With one driver, the DVM still failed. `/var/log/vmware-imc/toolsDeployPkg.log`
shows why:

```
[19:00:13] Cloud-init status is 'running'.
[19:00:18] Timed out waiting for cloud-init execution done.
[19:00:18] Ran DeployPkg_DeployPackageFromFile successfully
[19:00:18] Trigger reboot.
[19:00:19] Rebooting.
```

The reboot killed apt 45 s after it started. On the next boot cloud-init skipped
`package_update_upgrade_install` (marker written when the module started, before
the reboot), so the guest was left with

```
iHR ansible  9.2.0+dfsg-0ubuntu5
dpkg --audit: ansible, ansible-core, git, ca-certificates, openssh-*, python3.12 ...
```

and runcmd ran anyway (50 ms after `modules:final` started) against that broken
install. The playbook error "Invalid callback for stdout specified: yaml" was a
symptom of the half-installed ansible, not a playbook problem.

**vCD guest customization always reboots a Linux guest after applying its
customization spec. There is no cloud-init setting that prevents it.**

### Cause 3: no DHCP, so the address must come from the guest

```
data.vcd_network_routed.Kub_cluster_net02: dhcp_pool = toset([])
static_ip_pool = 192.168.100.2 - 192.168.100.100
```

Dropping customization (to drop the reboot) without giving cloud-init a way to
configure the address leaves the guest hanging at
`systemd-networkd-wait-online` with no IP at all — observed twice in the console.
That is why the vCD initscript existed: it was the only thing setting the
address.

## 3. Final design (commit 887ca0a)

- `customization { ... }` removed from the DVM, masters and workers;
- `templates/customization_node.sh` deleted (initscript, NoCloud seed, manual
  cloud-init calls — all gone);
- `bootcmd:` added to all three user-data templates: writes
  `/etc/netplan/01-netplan.yaml` and applies it;
- `packages:` and `runcmd:` unchanged.

## 4. Evidence — standalone DVM, same image, same guest properties, same user-data

```
boot                19:38:11   (single boot, no reboot)
bootcmd             19:40:25   netplan applied, 192.168.100.253 up
packages install    19:40:28 - 19:41:50
scripts_user        19:41:50   runcmd, strictly after the package stage
dpkg -l ansible     ii
dpkg --audit        (clean)
starter             /var/log/ansible-bootstrap.log written at 19:41:53,
                    playbook ran to "Kubernetes Cluster Automation Completed Successfully"
```

One cloud-init final stage, one runcmd, no reboot, no manual driver.

## 5. Rules for future changes here

1. Never start cloud-init by hand; one driver only (systemd).
2. Never enable vCD `customization` on a VM whose cloud-init installs packages: its
   reboot cuts the apt transaction and the module marker then hides the damage.
3. If the network has no DHCP, the address must be applied by cloud-init before
   its package stage (`bootcmd` or `network:`), not by a vCD initscript.
4. Do not put `apt-get` / `flock` / lock workarounds into runcmd: if packages are needed
   before runcmd, fix the ordering, not the symptom.

## 6. Status at the time of writing

Full cluster apply started 19:44:58 UTC with commit 887ca0a: network, edge LB and
DNAT created without the earlier NSX error; nodes being created (vCD clone times
5-9 minutes per VM today); DVM and its automatic ansible run follow.
Final confirmation is `/var/log/ansible-bootstrap.log` on the DVM reaching the end of
the playbook.
