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
    nat           = true
    preemptible   = true
  }
  
  description = "Конфигурация воркер-нод"
}

# SSH доступ
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH публичный ключ для доступа к ВМ."
  sensitive   = true
  
  validation {
    condition = var.ssh_public_key == "" || can(regex("^ssh-(rsa|ed25519|dss|ecdsa-sha2-nistp(256|384|521)) AAAA[0-9A-Za-z+/]+[=]{0,3}( .*)?\\s*$", var.ssh_public_key))
    error_message = "SSH публичный ключ должен быть в формате: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }
}

variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "Имя пользователя для SSH"
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


