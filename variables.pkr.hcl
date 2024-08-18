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
  default     = "2G"
  description = "The size of the disk to create"
}