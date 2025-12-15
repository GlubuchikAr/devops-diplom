locals {  
  # Общие настройки
  kubeconfig_path = var.kubeconfig_path != "" ? var.kubeconfig_path : "${path.module}/../kubernetes/kubespray/inventory/mycluster/artifacts/admin.conf"
  
  # Определяем, нужно ли использовать main или конкретный тег
  use_main_branch = var.diplom_tag == "" || var.diplom_tag == "latest"
  
  # Формируем URL в зависимости от значения diplom_tag
  diplom_yaml_url = local.use_main_branch ? "https://gitlab.com/artemglubuchik-group/artemglubuchik-project/-/raw/main/k8s/diplom.yaml?ref_type=heads" : "https://gitlab.com/artemglubuchik-group/artemglubuchik-project/-/raw/${var.diplom_tag}/k8s/diplom.yaml?ref_type=tags"

  # Получаем оригинальный YAML
  original_yaml = data.http.diplom_yaml.response_body
  
  # Применяем замены последовательно ко всему файлу
  # 1. Замена хоста grafana (если нужно)
  step1 = var.grafana_host != "grafana.aglubuchik.com" ? replace(
    local.original_yaml,
    "host: grafana.aglubuchik.com",
    "host: ${var.grafana_host}"
  ) : local.original_yaml
  
  # 2. Замена хоста diplom (если нужно)
  step2 = var.diplom_host != "diplom.aglubuchik.com" ? replace(
    local.step1,
    "host: diplom.aglubuchik.com",
    "host: ${var.diplom_host}"
  ) : local.step1
  
  # 3. Замена тега образа (только если не используется main branch)
  modified_diplom_yaml = local.use_main_branch ? local.step2 : replace(
    local.step2,
    "image: aglubuchik/diplom-application:[^\\s\\n\"]+",
    "image: aglubuchik/diplom-application:${var.diplom_tag}"
  )
}
