locals {
  # Генерация имен с учетом окружения
  name_prefix = "diplom-${var.environment}"
  
  # Cloud-init конфигурация
  # cloud_init_vars = {
  #   ssh_public_key = local.ssh_public_key
  #   ssh_username   = var.ssh_username
  #   packages       = concat([
  #     "mc",
  #     "git",
  #     "apt-transport-https",
  #     "ca-certificates",
  #     "curl",
  #     "gnupg",
  #     "lsb-release",
  #     "unattended-upgrades",
  #     "python3",
  #     "python3-pip",
  #   ], var.additional_packages)
  #   run_commands = concat([
  #     # Базовые настройки
  #     "systemctl disable --now apt-daily-upgrade.timer",
  #     "systemctl disable --now apt-daily.timer",
  #     "timedatectl set-timezone Europe/Moscow",
      
  #     # Отключение swap
  #     "swapoff -a",
  #     "sed -i '/ swap / s/^/#/' /etc/fstab",
  #   ], var.run_commands)
  # }
  
  # Метаданные для ВМ
  # ssh_public_key = try(
  #   # Если указан сам ключ
  #   var.ssh_public_key != "" ? var.ssh_public_key : 
  #   # Если указан путь к файлу
  #   var.ssh_public_key_file != "" ? file(var.ssh_public_key_file) :
  #   # По умолчанию или ошибка
  #   file("~/.ssh/id_rsa.pub"),
  #   file("~/.ssh/id_rsa.pub")  # fallback
  # )

  ssh_public_key = file("~/.ssh/aglubuchik.pub")

  instance_metadata = var.enable_cloud_init ? {
    serial-port-enable = 1
    ssh-keys           = "${var.ssh_username}:${local.ssh_public_key}"
    # user-data          = templatefile("${path.module}/templates/cloud-init.yml.tftpl", local.cloud_init_vars)
    user-data          = data.template_file.cloudinit.rendered
  } : {
    serial-port-enable = 1
    ssh-keys           = "${var.ssh_username}:${local.ssh_public_key}"
  }
  
  # Теги ресурсов
  resource_tags = merge({
    terraform   = "true"
    environment = var.environment
    project     = "diplom"
    createdby   = "terraform"
  }, var.common_tags)
}