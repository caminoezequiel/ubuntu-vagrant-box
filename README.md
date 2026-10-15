# Ubuntu Vagrant boxes

Turns an official Ubuntu ISO (live-server or desktop) into a VirtualBox Vagrant box with [Packer](https://developer.hashicorp.com/packer) and Ubuntu autoinstall, and publishes it as a GitHub Release. Prebuilt boxes are in this repository's [Releases](../../releases).

A box is a stock Ubuntu install plus only what Vagrant needs:

- `vagrant` user (password `vagrant`) with passwordless sudo
- Vagrant's insecure public key, which Vagrant replaces on first `vagrant up`
- `virtualbox-guest-utils` for shared folders
- Desktop only: `virtualbox-guest-x11` (display resizing, shared clipboard), automatic login, no welcome wizard or screen lock

## Build

Requirements: Packer, VirtualBox 7.x and Vagrant.

1. Download an ISO from [ubuntu.com](https://ubuntu.com/download) (or [releases.ubuntu.com](https://releases.ubuntu.com/)) into the project root.
2. Point `iso_url` in `vars.auto.pkrvars.hcl` at it. A releases.ubuntu.com URL also works; Packer then downloads the ISO itself.
3. Build:

   ```bash
   packer init .
   packer build .
   ```

Packer loads `vars.auto.pkrvars.hcl` automatically. It's committed with the default settings; to edit it without git reporting the change, run this once after cloning:

```bash
git update-index --skip-worktree vars.auto.pkrvars.hcl
```

To build another ISO without editing the file: `packer build -var iso_url=<iso> .`. Set `headless = true` to hide the VirtualBox window during the build. The ISO's checksum isn't verified.

The box is named after the ISO, without `live-`: `ubuntu-26.04.1-live-server-amd64.iso` becomes `ubuntu-26.04.1-server-amd64.box`, and `ubuntu-26.04.1-desktop-amd64.iso` becomes `ubuntu-26.04.1-desktop-amd64.box`. The build VM has 2 CPUs, 4 GB of memory and a 40 GB dynamically allocated disk; a build takes 15–40 minutes, the desktop being the slower one.

Troubleshooting:

- `Output directory exists`: a previous build was interrupted. Delete `output-ubuntu/` or run `packer build -force .`.
- VT-x/AMD-V "in use" error from VirtualBox: KVM is loaded. Run `sudo modprobe -r kvm_amd kvm` (or `kvm_intel`).

## Test

```bash
vagrant up                                          # boots the newest .box here and runs smoke tests
BOX=ubuntu-26.04.1-desktop-amd64.box vagrant up     # a specific one
vagrant destroy -f && vagrant box remove <box name> # before testing a rebuild
```

The smoke test checks sudo, the `/vagrant` shared folder, the machine ID and networking, plus automatic login on a desktop box. Desktop boxes open with the VM window shown and 4 GB of memory.

## Publish

Requires the [GitHub CLI](https://cli.github.com/), logged in, and all changes committed and pushed.

```bash
./publish.sh             # tag defaults to vYYYY.MM.DD
./publish.sh v2026.10.15
```

Every `.box` in the project root is uploaded to the same release, so delete any you don't want published. The release notes contain a ready-to-paste Vagrantfile snippet for each box:

```ruby
config.vm.box = "ubuntu-26.04.1-server-amd64"
config.vm.box_url = "https://github.com/<owner>/<repo>/releases/download/<tag>/ubuntu-26.04.1-server-amd64.box"
config.vm.box_download_checksum_type = "sha256"
config.vm.box_download_checksum = "<sha256>"
```

For a desktop box, add `vb.gui = true` and `vb.memory = 4096` to the `virtualbox` provider block.

## Layout

| Path | Purpose |
|---|---|
| `ubuntu.pkr.hcl` | Packer template |
| `vars.auto.pkrvars.hcl` | Build settings (`iso_url`, `headless`), loaded automatically |
| `http/user-data`, `http/meta-data` | Autoinstall config served to the installer |
| `provision.sh` | Makes the install Vagrant-ready (plus desktop tweaks when GNOME is installed) and shrinks it for export |
| `Vagrantfile` | Smoke test for a locally built box |
| `publish.sh` | Uploads the boxes as a GitHub Release |
