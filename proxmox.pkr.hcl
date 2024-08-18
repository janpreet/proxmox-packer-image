packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu-cloud" {
  iso_url           = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-${source.name}.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/SHA256SUMS"
  output_directory  = "output-${source.name}"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  disk_size         = var.disk_size
  format            = "qcow2"
  accelerator       = "kvm"
  ssh_username      = "ubuntu"
  ssh_password      = "ubuntu"
  ssh_timeout       = "20m"
  vm_name           = "ubuntu-cloud-base-${source.name}"
  memory            = var.memory
  cpus              = var.cpu_count
  headless          = true
  use_default_display = true
  qemu_binary       = source.name == "s390x" ? "qemu-system-s390x" : (source.name == "arm64" ? "qemu-system-aarch64" : "qemu-system-x86_64")
  machine_type      = source.name == "s390x" ? "s390-ccw-virtio" : (source.name == "arm64" ? "virt" : "q35")
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
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
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