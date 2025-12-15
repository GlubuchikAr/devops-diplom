locals {
  # Генерация имен с учетом окружения
  name_prefix = "diplom-${var.environment}"
  
  # Метаданные для ВМ
  instance_metadata = {
    serial-port-enable = 1
    ssh-keys           = "${var.ssh_username}:${var.ssh_public_key}"
    user-data          = data.template_file.cloudinit.rendered
  }
  
  # Теги ресурсов
  resource_tags = merge({
    terraform   = "true"
    environment = var.environment
    project     = "diplom"
    createdby   = "terraform"
  }, var.common_tags)
}