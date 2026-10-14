#!/bin/bash
set -euxo pipefail

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
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y virtualbox-guest-utils
