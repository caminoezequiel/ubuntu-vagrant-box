packer {
  required_plugins {
    virtualbox = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "Path or URL of an Ubuntu live-server or desktop ISO."
}

variable "headless" {
  type        = bool
  default     = false
  description = "Hide the VirtualBox window during the build."
}

locals {
  # ubuntu-26.04.1-live-server-amd64.iso -> ubuntu-26.04.1-server-amd64
  box_name = replace(trimsuffix(basename(var.iso_url), ".iso"), "-live-", "-")
}

source "virtualbox-iso" "ubuntu" {
  iso_url       = var.iso_url
  iso_checksum  = "none"
  guest_os_type = "Ubuntu_64"
  headless      = var.headless

  # Dynamically allocated, so unused space costs nothing; the desktop installer wants the room
  disk_size            = 40960
  hard_drive_interface = "sata"

  # Give the GRUB menu time to load, then edit the default entry and append autoinstall
  # args to its `linux` line (same layout on the server and desktop ISOs).
  # GRUB needs `\;` (HCL "\\;"), otherwise `;` is taken as a command separator.
  boot_wait = "10s"
  boot_command = [
    "<wait>e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<F10>"
  ]
  http_directory = "http"

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "60m"
  # The live server installer runs its own sshd, which rejects vagrant/vagrant; keep retrying until the installed system is up
  ssh_handshake_attempts = 1000
  shutdown_command       = "sudo shutdown -P now"

  # Guest utilities come from Ubuntu's packages instead (see provision.sh)
  guest_additions_mode = "disable"

  # Exported into the box; the display settings only matter for a desktop
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "4096", "--cpus", "2", "--nic1", "nat"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga", "--vram", "128", "--clipboard-mode", "bidirectional"]
  ]
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "sudo -E bash '{{ .Path }}'"
    script          = "provision.sh"
  }

  post-processor "vagrant" {
    output = "${local.box_name}.box"
  }
}
