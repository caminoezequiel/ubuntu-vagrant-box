# Smoke test for the box built by ubuntu.pkr.hcl.
#   packer build ubuntu.pkr.hcl && vagrant up
# Rebuilt the box? Run `vagrant destroy -f && vagrant box remove ubuntu-26.04-server` first.

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-26.04-server"
  # Adds the box automatically on the first `vagrant up` if it isn't installed yet
  config.vm.box_url = "file://#{File.expand_path("ubuntu-26.04-server-amd64-virtualbox.box", __dir__)}"
  config.vm.hostname = "ubuntu-test"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "ubuntu-26.04-test"
    vb.memory = 2048
    vb.cpus = 2
  end

  # Fails `vagrant up` if any of the box's basics are broken
  config.vm.provision "shell", name: "smoke-test", privileged: false, inline: <<-SHELL
    set -eu
    echo "== OS";            grep PRETTY_NAME /etc/os-release
    echo "== Kernel";        uname -r
    echo "== Passwordless sudo"; sudo -n true && echo ok
    echo "== Shared folder"; mountpoint -q /vagrant && ls /vagrant/Vagrantfile
    echo "== Machine ID";    test -s /etc/machine-id && cat /etc/machine-id
    echo "== Network";       getent hosts archive.ubuntu.com
    echo "== Disk";          df -h /
    echo "All checks passed"
  SHELL
end
