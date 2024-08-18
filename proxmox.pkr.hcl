
packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "ubuntu-cloud" {
  iso_url           = "https://cloud-images.ubuntu.com/${var.ubuntu_version}/current/${var.ubuntu_version}-server-cloudimg-amd64.img"
  iso_checksum      = "${var.image_checksums["amd64"]}"
  output_directory  = "output-amd64"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  disk_size         = "${var.disk_size}"
  format            = "qcow2"
  accelerator       = "tcg"
  ssh_username      = "ubuntu"
  ssh_password      = "${var.ssh_password}"
  ssh_timeout       = "30m"
  vm_name           = "ubuntu-cloud-base-amd64"
  net_device        = "virtio-net"
  disk_interface    = "virtio"
  boot_wait         = "2m"
  memory            = var.memory
  cpus              = var.cpu_count
  headless          = true
  qemu_binary       = "qemu-system-x86_64"
  qemuargs          = [
    ["-smp", "${var.cpu_count}"],
    ["-m", "${var.memory}M"],
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net,netdev=user.0"],
    ["-drive", "file=cloud-init.img,format=raw,if=virtio"],
    ["-smbios", "type=1,serial=ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"]
  ]
  http_content = {
    "/meta-data" = jsonencode({
      "instance-id"    = "packer-qemu-${var.ubuntu_version}"
      "local-hostname" = "ubuntu-cloud"
    })
    "/user-data" = yamlencode({
      "users" = [
        {
          "name"                = "ubuntu"
          "passwd"              = "${var.ssh_password}"
          "lock_passwd"         = false
          "ssh_pwauth"          = true
          "sudo"                = "ALL=(ALL) NOPASSWD:ALL"
        }
      ]
      "ssh_pwauth" = true
      "chpasswd" = {
        "expire" = false
      }
      "bootcmd" = [
        "sed -i 's/^#*\\s*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config",
        "sed -i 's/^#*\\s*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config",
        "systemctl restart sshd"
      ]
    })
  }
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
    output = "output-amd64/ubuntu-cloud-base-${var.ubuntu_version}-amd64.qcow2.gz"
  }
}