#!/usr/bin/env bash
# Fixes the iio-sensor-proxy selinux block
# Basically selinux won't let the iio-sensor-proxy to read and change the orientation
set -oue pipefail

semanager permissive -a iiosensorproxy_t
systemctl restart iio-sensor-proxy.service
