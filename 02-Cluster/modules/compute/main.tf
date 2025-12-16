# Создание VPC сети
resource "yandex_vpc_network" "main" {
  name        = "${local.name_prefix}-${var.vpc_name}"
  description = "VPC сеть для кластера Kubernetes"
  labels      = local.resource_tags
}

# Создание подсетей в разных зонах
resource "yandex_vpc_subnet" "subnet1" {
  name           = var.vpc_subnet.subnet1.name
  zone           = var.vpc_subnet.subnet1.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = var.vpc_subnet.subnet1.cidr
}

resource "yandex_vpc_subnet" "subnet2" {
  name           = var.vpc_subnet.subnet2.name
  zone           = var.vpc_subnet.subnet2.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = var.vpc_subnet.subnet2.cidr
}

# Создание cloud-init.yml
data "template_file" "cloudinit" {
 template = file("${path.module}/cloud-init.yml")
 vars = {
   ssh_public_key = var.ssh_public_key
   ssh_username = var.ssh_username
 }
}

# Определение образа для master
data "yandex_compute_image" "image-master" {
  family = var.master_nodes.image_family
}

# Создание мастер-нод
resource "yandex_compute_instance" "master" {
  count = var.master_nodes.count

  name               = "${local.name_prefix}-${var.master_nodes.name_prefix}-${count.index + 1}"
  folder_id          = var.folder_id
  platform_id        = var.master_nodes.platform_id
  zone               = var.vpc_subnet.subnet1.zone
  labels             = merge(local.resource_tags, {
    role = "master"
    node = "${var.master_nodes.name_prefix}-${count.index + 1}"
  })

  resources {
    cores         = var.master_nodes.cores
    memory        = var.master_nodes.memory
    core_fraction = var.master_nodes.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image-master.id
      type     = var.master_nodes.disk_type
      size     = var.master_nodes.disk_size
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = var.master_nodes.nat
  }

  scheduling_policy {
    preemptible = var.master_nodes.preemptible
  }

  metadata = local.instance_metadata

  allow_stopping_for_update = true

  # Жизненный цикл
  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
      boot_disk[0].initialize_params[0].image_id
    ]
    
    create_before_destroy = true
  }
}

# Определение образа для worker
data "yandex_compute_image" "image-worker" {
  family = var.worker_nodes.image_family
}

# Создание воркер-нод
resource "yandex_compute_instance" "worker" {
  count = var.worker_nodes.count

  name               = "${local.name_prefix}-${var.worker_nodes.name_prefix}-${count.index + 1}"
  folder_id          = var.folder_id
  platform_id        = var.worker_nodes.platform_id
  zone               = var.vpc_subnet.subnet2.zone
  labels             = merge(local.resource_tags, {
    role = "worker"
    node = "${var.worker_nodes.name_prefix}-${count.index + 1}"
  })

  resources {
    cores         = var.worker_nodes.cores
    memory        = var.worker_nodes.memory
    core_fraction = var.worker_nodes.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image-worker.image_id
      type     = var.worker_nodes.disk_type
      size     = var.worker_nodes.disk_size
    }
  }


  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat       = var.worker_nodes.nat
  }

  scheduling_policy {
    preemptible = var.worker_nodes.preemptible
  }

  metadata = local.instance_metadata

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
      boot_disk[0].initialize_params[0].image_id
    ]
    
    create_before_destroy = true
  }
}

# Генерация инвентаря для Kubespray
resource "local_file" "hosts_cfg_kubespray" {
  depends_on = [
    yandex_compute_instance.worker,
    yandex_compute_instance.master
  ]

  content = templatefile("${path.module}/templates/hosts.yaml.tftpl", {
    masters      = yandex_compute_instance.master
    workers      = yandex_compute_instance.worker
    ssh_user     = var.ssh_username
  })
  filename = "${path.module}/inventory/hosts.yaml"
}

# Обновление записей в /etc/hosts
resource "null_resource" "update_hosts" {
  count = var.update_hosts ? 1 : 0

  depends_on = [
    local_file.hosts_cfg_kubespray
  ]

  triggers = {
    master_ip = yandex_compute_instance.master[0].network_interface[0].nat_ip_address
    diplom_host = var.diplom_host
    grafana_host = var.grafana_host
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Удаляем старые записи (если они есть)
      echo "Для обновления записи в /etc/hosts введите пароль от SUDO"
      sudo sed -i '/${self.triggers.diplom_host}/d' /etc/hosts
      sudo sed -i '/${self.triggers.grafana_host}/d' /etc/hosts
      
      # Добавляем новые записи
      echo "${self.triggers.master_ip}  ${self.triggers.diplom_host}" | sudo tee -a /etc/hosts
      echo "${self.triggers.master_ip}  ${self.triggers.grafana_host}" | sudo tee -a /etc/hosts
      
      echo "Обновлены записи в /etc/hosts для IP: ${self.triggers.master_ip}"
    EOT
  }

  # При удалении инфраструктуры также удаляем записи
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Удаляем записи при уничтожении ресурсов
      echo "Для обновления записи в /etc/hosts введите пароль от SUDO"
      sudo sed -i '/${self.triggers.diplom_host}/d' /etc/hosts
      sudo sed -i '/${self.triggers.grafana_host}/d' /etc/hosts
      echo "Удалены записи из /etc/hosts"
    EOT
  }
}