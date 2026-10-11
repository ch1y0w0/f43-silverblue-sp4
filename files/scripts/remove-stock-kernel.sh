#!/usr/bin/env bash
# Remove the stock Fedora kernel so only kernel-surface remains in /usr/lib/modules.
set -oue pipefail

# --nodeps: other packages only need a "kernel" provide, which kernel-surface supplies.
rpm -e --nodeps kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra || true

# Delete leftover module dirs from the removed kernel(s)
rm -rf /usr/lib/modules/*

rpm -qa 'kernel*' || true
