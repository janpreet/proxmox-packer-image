packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu-cloud" {
  iso_url           = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-${var.current_arch}.img"
  iso_checksum      = "${var.image_checksums[var.current_arch]}"
  output_directory  = "output-${var.current_arch}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  disk_size         = "${var.disk_size}"
  format            = "qcow2"
  accelerator       = "tcg"
  ssh_username      = "ubuntu"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout       = "20m"
  vm_name           = "ubuntu-cloud-base-${var.current_arch}"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "10s"
  memory            = var.memory
  cpus              = var.cpu_count
  headless          = true
  qemu_binary       = var.current_arch == "arm64" ? "qemu-system-aarch64" : "qemu-system-x86_64"
  qemuargs          = [
    ["-smp", "${var.cpu_count}"],
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