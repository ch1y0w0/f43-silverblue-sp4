#!/usr/bin/env bash
# Build the initramfs for the linux-surface kernel (stock image initramfs was removed).
set -oue pipefail

KVER="$(ls /usr/lib/modules | head -n1)"
echo "Kernel found: ${KVER}"
case "${KVER}" in
  *surface*) ;;
  *) echo "ERROR: expected a *surface* kernel, got ${KVER}"; exit 1 ;;
esac

export DRACUT_NO_XATTR=1
# Add "--add-drivers" here if you use LUKS (see linux-surface wiki: Disk Encryption)
/usr/bin/dracut --no-hostonly --kver "${KVER}" --reproducible -v --add ostree \
  -f "/usr/lib/modules/${KVER}/initramfs.img"
chmod 0600 "/usr/lib/modules/${KVER}/initramfs.img"
