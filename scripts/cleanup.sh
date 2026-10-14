#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get -y autoremove --purge
apt-get -y clean
rm -rf /var/lib/apt/lists/*

# Each VM cloned from the box must get its own machine-id (systemd regenerates an empty one on boot)
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
cloud-init clean --logs || true

# Zero free space so the exported disk compresses well
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY
sync
