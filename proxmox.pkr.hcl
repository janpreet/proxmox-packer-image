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

source "qemu" "ubuntu-cloud" {
  iso_url           = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-${source.name}.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/SHA256SUMS"
  output_directory  = "output-${source.name}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  disk_size         = var.disk_size
  format            = "qcow2"
  accelerator       = "tcg"
  ssh_username      = "ubuntu"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout       = "60m"
  ssh_handshake_attempts = "100"
  vm_name           = "ubuntu-cloud-base-${source.name}"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  boot_command      = [
    "c<wait>",
    "linux /boot/vmlinuz root=/dev/vda1 console=tty1 console=ttyS0<enter><wait>",
    "initrd /boot/initrd<enter><wait>",
    "boot<enter><wait>"
  ]
  memory            = var.memory
  cpus              = var.cpu_count
  headless          = true
  use_default_display = true
  qemu_binary       = source.name == "arm64" ? "qemu-system-aarch64" : "qemu-system-x86_64"
  machine_type      = source.name == "arm64" ? "virt" : "q35"
  qemuargs = source.name == "arm64" ? [
    ["-cpu", "cortex-a57"],
    ["-machine", "virt"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
    ["-device", "usb-mouse"],
    ["-bios", "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net,netdev=user.0"]
  ] : [
    ["-cpu", "qemu64"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net,netdev=user.0"]
  ]
}

build {
  dynamic "source" {
    for_each = var.arch
    labels   = ["qemu.ubuntu-cloud"]
    content {
      name = source.value
    }
  }

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo sed -i 's/^#*\\s*PermitRootLogin\\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^#*\\s*PasswordAuthentication\\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "echo 'ubuntu:${var.ssh_password}' | sudo chpasswd",
      "sudo systemctl restart sshd",
      "ip addr show",
      "ss -tulpn",
      "sudo apt-get update",
      "sudo apt-get install -y qemu-guest-agent cloud-init",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo 'This image was created by ${var.author_name}' | sudo tee /etc/janpreet_signature",
      "sudo chmod 644 /etc/janpreet_signature"
    ]
  }

  post-processor "compress" {
    output = "output-${source.name}/ubuntu-cloud-base-${var.ubuntu_version}-${source.name}.qcow2.gz"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}