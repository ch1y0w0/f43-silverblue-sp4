#!/usr/bin/env bash
# Fixes the iptsd pen stopping by Fedora unit
set -oue pipefail
ln -sf /dev/null /etc/systemd/system/iptsd@.service
systemctl enable iptsd-pen.service
