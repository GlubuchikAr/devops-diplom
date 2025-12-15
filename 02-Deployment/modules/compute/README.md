### Модуль подготавливает сеть и ВМ для разорота K8S


- Создает сеть
- Создает 2 подсети, можно изменить с помощью переменной
```
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
```
- Создает Мастер ноды в подсети subnet1
```
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
```
- Создает Воркер ноды в подсети subnet2
```
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
```
- Создает инвентарь hosts.yaml для kubespray который будет использовать модуль [kubernetes](../kubernetes)
- Если переменная update_hosts = true, внесет изменения в /etc/hosts (требуется запуск от SUDO или ввод пароля во время выполнения манифеста)
добавит внешний IP мастера для хостов указанных в переменных 
```
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
```

Для доступа к ВМ нужно указать пользователя и открытый ключ
```
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

variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "Имя пользователя для SSH"
}
```

Можно настроить [cloud-init.yml](cloud-init.yml) для изменения настроек поднимаемых ВМ