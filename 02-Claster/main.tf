# Поднимает сеть, подсети, ВМ
module "compute" {
  source = "./modules/compute"

  cloud_id            = var.cloud_id
  folder_id           = var.folder_id
  ssh_username        = var.ssh_username
  ssh_public_key      = local.ssh_public_key
  update_hosts        = true
  diplom_host         = var.diplom_host
  grafana_host        = var.grafana_host
}

# Разворачивает кубернетис кластер
module "kubernetes" {
  source = "./modules/kubernetes"

  hosts_path    = module.compute.hosts_cfg_kubespray_path

  ssh_username  = var.ssh_username

  depends_on = [
    module.compute
  ]
}

# Функции модуля перенесены в отдельный проэкт

# # Разворачивает мониторинг, gitlab-runner и приложение
# module "applications" {
#   source = "./modules/applications"

#   grafana_admin_password = var.grafana_admin_password
#   gitlab_runner_token    = var.gitlab_runner_token
#   diplom_tag             = "latest"
#   diplom_host            = var.diplom_host
#   grafana_host           = var.grafana_host

#   depends_on = [
#     module.kubernetes
#   ]
# }
