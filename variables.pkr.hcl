variable "ubuntu_version" {
  type        = string
  default     = "focal"
  description = "Ubuntu version to use for the image"
}

variable "arch" {
  type        = list(string)
  default     = ["amd64", "arm64", "s390x"]
  description = "List of architectures to build images for"
}

variable "author_name" {
  type        = string
  default     = "Janpreet Singh"
  description = "Name of the image author"
}

variable "cpu_count" {
  type        = number
  default     = 2
  description = "The number of CPUs to allocate to the VM"
}

variable "memory" {
  type        = number
  default     = 1024
  description = "The amount of memory in MB to allocate to the VM"
}

variable "disk_size" {
  type        = string
  default     = "5G"
  description = "The size of the disk to create"
}

variable "ssh_password" {
  type    = string
  default = ""
}

variable "image_checksums" {
  type = map(string)
  default = {
    amd64 = "file:https://cloud-images.ubuntu.com/focal/current/SHA256SUMS"
    arm64 = "file:https://cloud-images.ubuntu.com/focal/current/SHA256SUMS"
  }
  description = "SHA256 checksums for different architecture images"
}

variable "current_arch" {
  type        = string
  default     = "amd64"
  description = "Current architecture to build (amd64 or arm64)"
}
