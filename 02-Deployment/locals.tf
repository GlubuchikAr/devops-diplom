locals {
  # Расширяем путь к файлу, если он указан
  expanded_ssh_key_path = var.ssh_public_key_file != "" ? pathexpand(var.ssh_public_key_file) : ""
  
  # Проверка, что хотя бы один источник указан
  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : (
    var.ssh_public_key_file != "" ? (
      fileexists(local.expanded_ssh_key_path) ? 
      file(local.expanded_ssh_key_path) : 
      error("Файл ${var.ssh_public_key_file} не найден по пути: ${local.expanded_ssh_key_path}")
    ) : error("Не указан SSH ключ! Укажите либо var.ssh_public_key, либо var.ssh_public_key_file")
  )
}