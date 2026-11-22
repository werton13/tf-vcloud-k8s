#!/usr/bin/env bash
# Grow the root and every LVM-backed data filesystem into the space the disk has.
#
# A clone carries the template's partition table: the disk here is 20 GiB while
# sda3 is 8.29 GiB, so / reports 7.6 GiB and ~11 GiB stay unusable. A later resize
# only grows the virtual disk (the controller drains, powers off, resizes and
# powers the worker on again), so the guest has to grow its partition, PV, LV and
# filesystem at boot - on every boot, because that is when the new space appears.
#
# Idempotent: on a disk that already fills its volume group every step is a
# no-op, and nothing here can shrink anything.
set -uo pipefail

LOG=/var/log/vcd-grow-disks.log
exec >>"$LOG" 2>&1
log() { echo "[$(date -Is)] $*"; }

grow_fs() { # lvpath mount fstype
  local lv="$1" mnt="$2" fs="$3" out
  case "$fs" in
    ext2|ext3|ext4)
      out=$(resize2fs "$lv" 2>&1) || { log "resize2fs $lv failed: $out"; return 1; }
      ;;
    xfs)
      out=$(xfs_growfs "$mnt" 2>&1) || { log "xfs_growfs $mnt failed: $out"; return 1; }
      ;;
    *)
      log "filesystem $fs on $mnt is not grown automatically"
      return 0
      ;;
  esac
  log "grew $mnt: $(df -h "$mnt" 2>/dev/null | tail -n1)"
}

grow_partition() { # pv, if it is /dev/sdXN
  local pv="$1" disk part out
  if [[ "$pv" =~ ^/dev/([a-z]+)([0-9]+)$ ]]; then
    disk="/dev/${BASH_REMATCH[1]}"
    part="${BASH_REMATCH[2]}"
    if command -v growpart >/dev/null 2>&1; then
      out=$(growpart "$disk" "$part" 2>&1)
      log "growpart $disk $part -> rc=$? ${out:-}"
    elif command -v parted >/dev/null 2>&1; then
      out=$(parted -s "$disk" resizepart "$part" 100% 2>&1)
      log "parted resizepart $disk $part -> rc=$? ${out:-}"
    else
      log "neither growpart nor parted is installed; cannot grow $pv"
      return 0
    fi
    udevadm settle >/dev/null 2>&1 || true
  fi
}

grow_lv() { # lvpath mount
  local lv="$1" mnt="$2" vg pv free fs out
  vg=$(lvs --noheadings -o vg_name "$lv" 2>/dev/null | tr -d ' ')
  [[ -z "$vg" ]] && return 0
  pv=$(pvs --noheadings -o pv_name --select "vg_name=$vg" 2>/dev/null | tr -d ' ' | head -n1)
  if [[ -n "$pv" ]]; then
    grow_partition "$pv"
    out=$(pvresize "$pv" 2>&1)
    log "pvresize $pv -> ${out:-ok}"
  fi
  free=$(vgs --noheadings -o vg_free_count "$vg" 2>/dev/null | tr -d ' ')
  if [[ "${free:-0}" -gt 0 ]]; then
    out=$(lvextend -y -l +100%FREE "$lv" 2>&1) || {
      sleep 3
      udevadm settle >/dev/null 2>&1 || true
      out=$(lvextend -y -l +100%FREE "$lv" 2>&1)
    }
    log "lvextend $lv: $out"
  fi
  fs=$(findmnt -n -o FSTYPE "$mnt" 2>/dev/null || true)
  grow_fs "$lv" "$mnt" "${fs:-ext4}" || true
}

log "growing filesystems into the space the disks have"
# every mounted filesystem that lives on a logical volume, the root included
while read -r tgt src fs; do
  [[ -n "${tgt:-}" && "$src" == /dev/mapper/* ]] || continue
  grow_lv "$src" "$tgt" || log "growth of $tgt failed; continuing"
done < <(findmnt -lno TARGET,SOURCE,FSTYPE 2>/dev/null)
log "done"
exit 0
