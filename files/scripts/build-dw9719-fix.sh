#!/usr/bin/env bash
set -euo pipefail

KERNEL=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-surface)
echo "Building fixed dw9719 for kernel $KERNEL"

WORKDIR=/tmp/dw9719-fix
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Download the exact source that matches the kernel series
curl -fsSL -o dw9719.c \
  "https://raw.githubusercontent.com/linux-surface/kernel/v6.19-surface/drivers/media/i2c/dw9719.c"

# ---------------------------------------------------------------
# 1. Insert the i2c_device_id table RIGHT AFTER the of_table
# ---------------------------------------------------------------
# Find the line with MODULE_DEVICE_TABLE(of, ...) and insert after it
python3 - <<'PY'
from pathlib import Path
src = Path("dw9719.c").read_text()

table = '''
static const struct i2c_device_id dw9719_id_table[] = {
	{ .name = "dw9718s", .driver_data = (kernel_ulong_t)DW9718S },
	{ .name = "dw9719",  .driver_data = (kernel_ulong_t)DW9719  },
	{ .name = "dw9761",  .driver_data = (kernel_ulong_t)DW9761  },
	{ .name = "dw9800k", .driver_data = (kernel_ulong_t)DW9800K },
	{ }
};
MODULE_DEVICE_TABLE(i2c, dw9719_id_table);
'''

marker = "MODULE_DEVICE_TABLE(of, dw9719_of_table);"
if marker not in src:
    raise SystemExit("Could not find of_table marker")

src = src.replace(marker, marker + "\n" + table)

# ---------------------------------------------------------------
# 2. Add .id_table = dw9719_id_table inside the i2c_driver struct
# ---------------------------------------------------------------
# Look for the probe line and insert the id_table after it
old = ".probe = dw9719_probe,"
new = ".probe = dw9719_probe,\n\t.id_table = dw9719_id_table,"
if old not in src:
    raise SystemExit("Could not find probe line")

src = src.replace(old, new, 1)

Path("dw9719.c").write_text(src)
print("Source patched successfully")
PY

# Minimal Makefile
cat > Makefile << EOF
obj-m := dw9719.o
KDIR := /lib/modules/${KERNEL}/build
PWD  := \$(shell pwd)

all:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules

clean:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) clean
EOF

# Build
make -j$(nproc)

# Install as override (this wins over the in-tree module)
install -D -m 644 dw9719.ko "/usr/lib/modules/${KERNEL}/updates/dw9719.ko"
depmod -a "${KERNEL}"

echo "✓ Fixed dw9719.ko installed for $KERNEL"
ls -l "/usr/lib/modules/${KERNEL}/updates/dw9719.ko"
