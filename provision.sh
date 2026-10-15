#!/bin/bash
# Runs inside the build VM: makes the fresh install Vagrant-ready, then shrinks it for export.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Vagrant insecure public keys (Vagrant swaps them for a generated key on first `vagrant up`)
install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
cat > /home/vagrant/.ssh/authorized_keys <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1YdxBpNlzxDqfJyw/QKow1F+wvG9hXGoqiysfJOn5Y vagrant insecure public key
EOF
chmod 600 /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

# Speed up SSH logins
echo 'UseDNS no' > /etc/ssh/sshd_config.d/vagrant.conf

# Guest utilities (vboxsf shared folders for /vagrant); the kernel modules ship with Ubuntu's kernel
apt-get update
apt-get install -y virtualbox-guest-utils

# Desktop installs only
if [ -d /etc/gdm3 ]; then
  # Display resizing and shared clipboard under VirtualBox
  apt-get install -y virtualbox-guest-x11

  # Log the vagrant user straight into the desktop
  cat > /etc/gdm3/custom.conf <<'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=vagrant
EOF

  # Skip GNOME's first-login welcome wizard
  install -d -o vagrant -g vagrant /home/vagrant/.config
  echo yes > /home/vagrant/.config/gnome-initial-setup-done
  chown vagrant:vagrant /home/vagrant/.config/gnome-initial-setup-done

  # No screen lock or blanking, which is just in the way on a throwaway VM
  install -d /etc/dconf/profile /etc/dconf/db/local.d
  printf 'user-db:user\nsystem-db:local\n' > /etc/dconf/profile/user
  cat > /etc/dconf/db/local.d/00-vagrant <<'EOF'
[org/gnome/desktop/screensaver]
lock-enabled=false

[org/gnome/desktop/session]
idle-delay=uint32 0
EOF
  dconf update
fi

# Cleanup: purge unused packages and clean apt caches
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean
# Optional: comment if you mind forcing users to run 'apt update' on first boot
rm -rf /var/lib/apt/lists/*

# Each VM cloned from the box must get its own machine-id (systemd regenerates an empty one on boot)
echo -n > /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id || true

cloud-init clean --logs || true

# Clear system logs to free up hidden space
find /var/log -type f -exec truncate -s 0 {} \;

# Zero free space so the exported disk compresses well
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY
sync
