# Основные параметры облака
variable "cloud_id" {
  type        = string
  description = "ID облака Yandex Cloud"
  validation {
    condition     = length(var.cloud_id) > 0
    error_message = "Cloud ID не может быть пустым"
  }
}

variable "folder_id" {
  type        = string
  description = "ID каталога Yandex Cloud"
  validation {
    condition     = length(var.folder_id) > 0
    error_message = "Folder ID не может быть пустым"
  }
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Зона по умолчанию"
}

# Сетевые настройки
variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "Имя VPC сети"
}

variable "vpc_subnet" {
  type        = map(object({
    name = string,
    zone = string,
    cidr = list(string)
    }))
  default     = {
    subnet1  = {
        name = "subnet1",
        zone = "ru-central1-a",
        cidr = ["192.168.10.0/24"]
        },
    subnet2 = {
        name = "subnet2",
        zone = "ru-central1-b",
        cidr = ["192.168.20.0/24"]
    }}
  
  description = "Конфигурация подсетей"
}

# Конфигурация ВМ
variable "master_nodes" {
  type = object({
    count         = number
    name_prefix   = string
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    disk_type     = string
    image_family  = string
    nat           = bool
    preemptible   = bool
    zones         = list(string)
  })
  
  default = {
    count         = 1
    name_prefix   = "master"
    platform_id   = "standard-v1"
    cores         = 2
    memory        = 4
    core_fraction = 100
    disk_size     = 20
    disk_type     = "network-ssd"
    image_family  = "ubuntu-2204-lts"
    nat           = true
    preemptible   = true
    zones         = ["ru-central1-a"]
  }
  
  description = "Конфигурация мастер-нод"
}

variable "worker_nodes" {
  type = object({
    count         = number
    name_prefix   = string
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    disk_type     = string
    image_family  = string
    nat           = bool
    preemptible   = bool
    zones         = list(string)
  })
  
  default = {
    count         = 2
    name_prefix   = "worker"
    platform_id   = "standard-v1"
    cores         = 4
    memory        = 8
    core_fraction = 100
    disk_size     = 30
    disk_type     = "network-hdd"
    image_family  = "ubuntu-2204-lts"
    nat           = false
    preemptible   = true
    zones         = ["ru-central1-a", "ru-central1-b"]
  }
  
  description = "Конфигурация воркер-нод"
}

# SSH доступ
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = <<-EOT
    SSH публичный ключ для доступа к ВМ.
    Может быть указан напрямую или через переменную ssh_public_key_file.
    Формат: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
    Приоритет: ssh_public_key > ssh_public_key_file
  EOT
  sensitive   = true
  
  validation {
    condition     = var.ssh_public_key == "" || can(regex("^ssh-(rsa|ed25519|dss|ecdsa-sha2-nistp(256|384|521)) AAAA[0-9A-Za-z+/]+[=]{0,3}( .*)?$", var.ssh_public_key))
    error_message = "SSH публичный ключ должен быть в формате: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }
}

variable "ssh_public_key_file" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = <<-EOT
    Путь до файла с публичным SSH ключом.
    Используется, если ssh_public_key не указан.
    Поддерживаются абсолютные и относительные пути.
    Может содержать ~ для домашней директории.
  EOT
  
  validation {
    condition     = var.ssh_public_key_file == "" || can(regex("^[~/a-zA-Z0-9_.\\-/]+$", var.ssh_public_key_file))
    error_message = "Некорректный путь к файлу SSH ключа"
  }
}


variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "Имя пользователя для SSH"
}

# Cloud-init настройки
variable "enable_cloud_init" {
  type        = bool
  default     = true
  description = "Включить cloud-init настройку"
}

variable "additional_packages" {
  type        = list(string)
  default     = []
  description = "Дополнительные пакеты для установки"
}

variable "run_commands" {
  type        = list(string)
  default     = []
  description = "Дополнительные команды для выполнения"
}

# Теги и метки
variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Общие теги для всех ресурсов"
}

variable "environment" {
  type        = string
  default     = "development"
  description = "Окружение (development/staging/production)"
}

variable "update_hosts" {
  description = "Нужно ли добавить записи в /etc/hosts, Нужны права sudo"
  type        = bool
  default     = false
}

variable "diplom_host" {
  description = "Host для доступа к странице диплома"
  type        = string
  default     = "diplom.aglubuchik.com"
}

variable "grafana_host" {
  description = "Host для доступа к странице мониторинга"
  type        = string
  default     = "grafana.aglubuchik.com"
}

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

variable "gitlab_runner_token" {
  type        = string
  description = "GitLab Runner registration token"
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true 
  description = "Admin password for Grafana"
}

