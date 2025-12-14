locals {
  ssh_public_key = file("~/.ssh/aglubuchik.pub")
  
  # Общие настройки
  kubeconfig_path = "${path.module}/../kubernetes/kubespray/inventory/mycluster/artifacts/admin.conf"
  
  # Prometheus Stack значения
  prometheus_values = {
    grafana = {
      adminPassword = var.grafana_admin_password
    }
  }
  
  # Ingress Nginx значения
  ingress_nginx_values = {
    controller = {
      service = {
        nodePorts = {
          http = var.ingress_http_nodeport
        }
      }
      replicaCount = 2
    }
  }
  
  # GitLab Runner значения
  gitlab_runner_values = {
    gitlabUrl = var.gitlab_url
    runnerRegistrationToken = var.gitlab_runner_token
    revisionHistoryLimit = 3
    
    rbac = {
      create = true
      rules = [
        {
          apiGroups = [""]
          resources = ["pods", "secrets", "configmaps"]
          verbs     = ["get", "list", "watch", "create", "patch", "delete", "update"]
        },
        {
          apiGroups = [""]
          resources = ["pods/exec", "pods/attach"]
          verbs     = ["create", "patch", "delete"]
        },
        {
          apiGroups = ["apps"]
          resources = ["deployments"]
          verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
        }
      ]
      clusterWideAccess = false
      podSecurityPolicy = {
        enabled      = false
        resourceNames = ["gitlab-runner"]
      }
    }
  }

  # Определяем, нужно ли использовать main или конкретный тег
  use_main_branch = var.diplom_tag == "" || var.diplom_tag == "latest"
  
  # Формируем URL в зависимости от значения diplom_tag
  diplom_yaml_url = local.use_main_branch ? "https://gitlab.com/artemglubuchik-group/artemglubuchik-project/-/raw/main/k8s/diplom.yaml?ref_type=heads" : "https://gitlab.com/artemglubuchik-group/artemglubuchik-project/-/raw/${var.diplom_tag}/k8s/diplom.yaml?ref_type=tags"

  # Разделяем документы в YAML файле
  diplom_yaml_docs = try(split("---", data.http.diplom_yaml.response_body), [])
  
  # Определяем, нужно ли менять тег образа
  # Если use_main_branch = true (main/latest), то не меняем
  # Если use_main_branch = false (указан конкретный тег), то меняем
  modified_diplom_yaml = local.use_main_branch ? data.http.diplom_yaml.response_body : join("---", [
      for doc in local.diplom_yaml_docs : 
      length(regexall("kind: Deployment", doc)) > 0 ? 
      replace(doc, 
        "image: aglubuchik/diplom-application:[^\\s\\n\"]+", 
        "image: aglubuchik/diplom-application:${var.diplom_tag}") : 
      doc
    ])
}