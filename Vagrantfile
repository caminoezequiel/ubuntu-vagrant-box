# Example that boots a locally built box and smoke-tests it:
#   vagrant up                                     # the newest *.box here
#   BOX=ubuntu-26.04.1-desktop-amd64.box vagrant up
# Rebuilt the box? Run `vagrant destroy -f && vagrant box remove <box name>` first.

box_file = ENV.fetch("BOX") { Dir["#{__dir__}/*.box"].max_by { |f| File.mtime(f) } || "none.box" }
box_name = File.basename(box_file, ".box")
desktop = box_name.include?("desktop")

Vagrant.configure("2") do |config|
  config.vm.box = box_name
  # Adds the box automatically on the first `vagrant up` if it isn't installed yet
  config.vm.box_url = "file://#{File.expand_path(box_file, __dir__)}"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = desktop ? 4096 : 2048
    vb.gui = desktop
  end

  # Fails `vagrant up` if any of the box's basics are broken
  config.vm.provision "shell", name: "smoke-test", privileged: false, inline: <<-SHELL
    set -eu
    echo "== OS";            grep PRETTY_NAME /etc/os-release
    echo "== Passwordless sudo"; sudo -n true && echo ok
    echo "== Shared folder"; mountpoint -q /vagrant && ls /vagrant/Vagrantfile
    echo "== Machine ID";    test -s /etc/machine-id && cat /etc/machine-id
    echo "== Network";       getent hosts archive.ubuntu.com
    if [ -d /etc/gdm3 ]; then
      echo "== Auto-login";  timeout 120 sh -c 'until pgrep -u vagrant -x gnome-shell; do sleep 2; done'
    fi
    echo "All checks passed"
  SHELL
end
