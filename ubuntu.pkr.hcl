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

variable "ubuntu_version" {
  type        = string
  default     = "26.04.1"
  description = "Ubuntu point release of the live-server ISO."
}

variable "iso_checksum" {
  type        = string
  default     = "sha256:cc8a95cde20f6ced61a322420de00f10cc3c90ced545daa46cb9c1a117f1d927"
  description = "Checksum of the ISO, from https://releases.ubuntu.com/<version>/SHA256SUMS."
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type        = number
  default     = 4096
  description = "Build VM memory in MB. Vagrantfiles set their own."
}

variable "disk_size" {
  type        = number
  default     = 20480
  description = "Disk size in MB."
}

variable "headless" {
  type        = bool
  default     = false
  description = "Hide the VirtualBox window during the build."
}

locals {
  iso_name = "ubuntu-${var.ubuntu_version}-live-server-amd64.iso"
  # x.y of the point release, e.g. 26.04
  box_version = join(".", slice(split(".", var.ubuntu_version), 0, 2))
}

source "virtualbox-iso" "ubuntu" {
  # Give the GRUB menu time to load before typing
  boot_wait = "10s"

  # Edit the default GRUB entry and append autoinstall args to the `linux` line.
  # GRUB needs `\;` (HCL "\\;"), otherwise `;` is taken as a command separator.
  boot_command = [
    "<wait>e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<F10>"
  ]

  guest_os_type = "Ubuntu_64"
  # A copy of the ISO in the project root is used if present, otherwise it is downloaded
  iso_urls = [
    local.iso_name,
    "https://releases.ubuntu.com/${var.ubuntu_version}/${local.iso_name}"
  ]
  iso_checksum         = var.iso_checksum
  http_directory       = "http"
  disk_size            = var.disk_size
  hard_drive_interface = "sata"
  headless             = var.headless

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "30m"
  # The live installer runs its own sshd, which rejects vagrant/vagrant; keep retrying until the installed system is up
  ssh_handshake_attempts = 1000

  shutdown_command = "sudo shutdown -P now"

  # Guest utilities come from Ubuntu's packages instead (see scripts/vagrant.sh)
  guest_additions_mode = "disable"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "${var.memory}"],
    ["modifyvm", "{{.Name}}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{.Name}}", "--nic1", "nat"]
  ]
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "sudo -E bash '{{ .Path }}'"
    scripts = [
      "scripts/vagrant.sh",
      "scripts/cleanup.sh"
    ]
  }

  post-processor "vagrant" {
    output = "ubuntu-${local.box_version}-server-amd64-{{ .Provider }}.box"
  }
}
