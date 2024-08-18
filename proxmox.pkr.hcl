packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "ssh_password" {
  type    = string
  default = ""
}

variable "ubuntu_version" {
  type    = string
  default = "focal"
}

source "qemu" "ubuntu-cloud" {
  iso_url           = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-${source.name}.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/SHA256SUMS"
  output_directory  = "output-${source.name}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  disk_size         = "5G"
  format            = "qcow2"
  accelerator       = "tcg"
  ssh_username      = "ubuntu"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout       = "20m"
  vm_name           = "ubuntu-cloud-base-${source.name}"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  memory            = 1024
  cpus              = 2
  headless          = true
  qemu_binary       = source.name == "arm64" ? "qemu-system-aarch64" : "qemu-system-x86_64"
  qemuargs          = [
    ["-smp", "2"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net,netdev=user.0"]
  ]
}

build {
  name    = "ubuntu-cloud-image"
  sources = ["source.qemu.ubuntu-cloud"]

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent",
      "sudo apt-get clean",
      "echo 'ubuntu:${var.ssh_password}' | sudo chpasswd",
      "echo 'Image built successfully'"
    ]
  }

  post-processor "compress" {
    output = "output-${source.name}/ubuntu-cloud-base-${var.ubuntu_version}-${source.name}.qcow2.gz"
  }
}