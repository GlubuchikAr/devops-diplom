variable "pip3_install" {
  type = list(string)
  default = [
    "ansible"
  ]
  description = "Что устанавливаем через pip3"
}

variable "hosts_path" {
  type        = string
  default     = "../compute/inventory/hosts.yaml"
  description = "Путь к файлу hosts.yaml"
}

variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "Имя пользователя для SSH"
}

