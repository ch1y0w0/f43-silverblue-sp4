#!/usr/bin/env bash
# Mark the iio-sensor-proxy SELinux domain permissive (denials are logged, not enforced)
set -oue pipefail

cat > /tmp/iiosp-permissive.cil <<'EOF'
(typepermissive iiosensorproxy_t)
EOF

semodule -n -i /tmp/iiosp-permissive.cil
rm -f /tmp/iiosp-permissive.cil
