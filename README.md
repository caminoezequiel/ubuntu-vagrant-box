# Ubuntu 26.04 Server Vagrant box

A minimal Ubuntu Server 26.04 LTS box for VirtualBox, built from the official live-server ISO with [Packer](https://developer.hashicorp.com/packer) and Ubuntu autoinstall. Prebuilt boxes are attached to this repository's [Releases](../../releases).

It contains a stock Ubuntu Server install plus only what Vagrant needs:

- `vagrant` user (password `vagrant`) with passwordless sudo
- Vagrant's insecure public key, which Vagrant replaces on first `vagrant up`
- `virtualbox-guest-utils` for shared folders

## Using a released box

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-26.04-server"
  config.vm.box_url = "https://github.com/<owner>/<repo>/releases/download/<tag>/ubuntu-26.04-server-amd64-virtualbox.box"
  config.vm.box_download_checksum_type = "sha256"
  config.vm.box_download_checksum = "<sha256 from the release notes>"
end
```

The exact lines are printed by `publish.sh` and included in each release's notes.

## Building

Requirements: Packer, VirtualBox 7.x and Vagrant.

```bash
packer init .
packer build ubuntu.pkr.hcl
```

The ISO is downloaded from releases.ubuntu.com unless `ubuntu-26.04.1-live-server-amd64.iso` is already in the project root. The build takes 15–30 minutes and produces `ubuntu-26.04-server-amd64-virtualbox.box`.

Variables can be overridden with `-var`, e.g. `-var headless=true` or `-var memory=8192`. See `ubuntu.pkr.hcl` for the full list. For a newer point release, set both `ubuntu_version` and `iso_checksum`.

If VirtualBox fails to start the VM with a VT-x/AMD-V "in use" error, KVM is loaded: `sudo modprobe -r kvm_amd kvm` (or `kvm_intel`).

## Testing

```bash
vagrant up        # imports the local .box and runs smoke tests
vagrant destroy -f && vagrant box remove ubuntu-26.04-server   # before testing a rebuild
```

## Publishing

Requires the [GitHub CLI](https://cli.github.com/), logged in, and all changes committed and pushed.

```bash
./publish.sh            # tag defaults to vYYYY.MM.DD
./publish.sh v2026.10.14
```

## Layout

| Path | Purpose |
|---|---|
| `ubuntu.pkr.hcl` | Packer template |
| `http/user-data`, `http/meta-data` | Autoinstall config served to the installer |
| `scripts/vagrant.sh` | Vagrant key, SSH tweaks, guest utilities |
| `scripts/cleanup.sh` | Shrinks and generalizes the image before export |
| `Vagrantfile` | Smoke test for a locally built box |
| `publish.sh` | Uploads the box as a GitHub Release |
