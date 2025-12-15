# SSH подключения
output "ssh_connection_strings" {
  value = [
    for idx, instance in yandex_compute_instance.master : 
    "ssh ${var.ssh_username}@${try(instance.network_interface[0].nat_ip_address, instance.network_interface[0].ip_address)}"
  ]
  description = "Строки для SSH подключения к мастер-нодам"
  sensitive   = true
}

output "ssh_connection_details" {
  value = {
    username    = var.ssh_username
    key_type    = try(split(" ", var.ssh_public_key)[0], "unknown")
    key_fingerprint = try(
      # Генерация fingerprint из публичного ключа
      base64sha256(var.ssh_public_key),
      "unknown"
    )
  }
  description = "Детальная информация для SSH подключения"
  sensitive   = true
}


# Все ноды вместе
output "all_nodes" {
  value = concat(
    [
      for idx, instance in yandex_compute_instance.master : {
        role       = "master"
        id         = instance.id
        name       = instance.name
        private_ip = instance.network_interface[0].ip_address
        public_ip  = try(instance.network_interface[0].nat_ip_address, null)
        hostname   = "master-${idx + 1}"
      }
    ],
    [
      for idx, instance in yandex_compute_instance.worker : {
        role       = "worker"
        id         = instance.id
        name       = instance.name
        private_ip = instance.network_interface[0].ip_address
        public_ip  = try(instance.network_interface[0].nat_ip_address, null)
        hostname   = "worker-${idx + 1}"
      }
    ]
  )
  description = "Все ноды кластера"
}

# IP адреса для Kubespray
output "kubespray_inventory" {
  value = {
    masters = [
      for idx, instance in yandex_compute_instance.master : {
        ip          = instance.network_interface[0].ip_address
        access_ip   = try(instance.network_interface[0].nat_ip_address, instance.network_interface[0].ip_address)
        hostname    = "master-${idx + 1}"
        node_name   = instance.name
      }
    ]
    workers = [
      for idx, instance in yandex_compute_instance.worker : {
        ip          = instance.network_interface[0].ip_address
        access_ip   = instance.network_interface[0].ip_address
        hostname    = "worker-${idx + 1}"
        node_name   = instance.name
      }
    ]
  }
  description = "Инвентарь для Kubespray"
}

output "hosts_cfg_kubespray_path" {
  value = local_file.hosts_cfg_kubespray.filename
}