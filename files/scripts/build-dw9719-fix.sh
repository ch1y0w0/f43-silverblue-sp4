#!/usr/bin/env bash
# Script to fix the dropped camera table from kernel
set -euo pipefail

KERNEL=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-surface)
echo "Building fixed dw9719 for kernel $KERNEL"

mkdir -p /tmp/dw9719-fix
cd /tmp/dw9719-fix

# Get the source that matches the kernel
curl -L -o dw9719.c \
  "https://raw.githubusercontent.com/linux-surface/kernel/v6.19-surface/drivers/media/i2c/dw9719.c"

# Apply the two missing pieces
cat >> dw9719.c << 'EOF'

static const struct i2c_device_id dw9719_id_table[] = {
	{ .name = "dw9718s", .driver_data = (kernel_ulong_t)DW9718S },
	{ .name = "dw9719",  .driver_data = (kernel_ulong_t)DW9719  },
	{ .name = "dw9761",  .driver_data = (kernel_ulong_t)DW9761  },
	{ .name = "dw9800k", .driver_data = (kernel_ulong_t)DW9800K },
	{ }
};
MODULE_DEVICE_TABLE(i2c, dw9719_id_table);
EOF

# Insert .id_table into the driver struct (simple reliable way)
sed -i 's/\.probe = dw9719_probe,/\.probe = dw9719_probe,\n\t.id_table = dw9719_id_table,/' dw9719.c

# Minimal Makefile
cat > Makefile << EOF
obj-m := dw9719.o
KDIR := /lib/modules/${KERNEL}/build
all:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules
EOF

# Build
make

# Install as override
install -D -m 644 dw9719.ko /usr/lib/modules/${KERNEL}/updates/dw9719.ko
depmod -a ${KERNEL}

echo "Fixed dw9719 installed for $KERNEL"
