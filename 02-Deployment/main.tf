# Поднимает сеть, подсети, ВМ
module "compute" {
  source = "./modules/compute"

  cloud_id            = var.cloud_id
  folder_id           = var.folder_id
#  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCf+mkgGwx3KKMFm5TYSYa/2Y1vciycnp4Oc6yBUOMP/Ykm7VHpSTqnUlYIrXqKEoWxla45xPcZBSFdyRvA95EGgHpbh3B5mszmcH+8OSBeAQtkk6A6tLEAhRMShNwHTp65tAXGxtKW0gNlHzne/+5fCnI4UYK1Ig+cC8bOhLbnNEQKMYzNvSwHarQC3buCLKgW/S0GGjVqfjX9ho0FoZhuh2wB9cF5sB8sKBKn8KQ12IEHZyPzqas2SnuBWHAkOqlkprBRp5WxZhs7cLUjfnd4qtlKCp5J+agCKHamn7h2tFTNwNMGd9EJfIPlE54vjz0tI9UD8nKrMUx6R95RC8jlK3nSv1akhwRN4o3soWHrGQgiqpI2Z145bj38Hg8KCEzDNr5H2iKWoCOTRAGb3odIysENMqUQtbk6jql7gJqd6tLgA8VOg75B/fFFLpGCVjhy5rCYXWwAU1h/X2EjxQlAeE789sW2bHisiRzG9loGNWFTuH2rWdakHxH9Tg5dbTE= glubuchik@glubuchik-pc"
  update_hosts        = true
}

# Разворачивает кубернетис кластер
module "kubernetes" {
  source = "./modules/kubernetes"

  hosts_path = module.compute.hosts_cfg_kubespray_path

  depends_on = [
    module.compute
  ]
}

locals {
  kubeconfig_path = "${path.module}/kubeconfig"
}

resource "null_resource" "copy_kubeconfig" {
  depends_on = [module.kubernetes]
  
  provisioner "local-exec" {
    command = "cp ${path.module}/modules/kubernetes/kubespray/inventory/mycluster/artifacts/admin.conf ${local.kubeconfig_path}"
  }
}

# Разворачивает мониторинг, gitlab-runner и приложение
module "applications" {
  source = "./modules/applications"

  grafana_admin_password = var.grafana_admin_password
  gitlab_runner_token = var.gitlab_runner_token
  diplom_tag = "v1.0.2"

  depends_on = [
    module.kubernetes,
    null_resource.copy_kubeconfig
  ]
}