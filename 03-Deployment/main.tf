# Ожидание готовности кластера
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      timeout 600 bash -c 'until kubectl --kubeconfig=${local.kubeconfig_path} get nodes 2>/dev/null; do echo "Waiting for cluster..."; sleep 10; done'
      kubectl --kubeconfig=${local.kubeconfig_path} wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  }
}

# Установка kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  values = var.prometheus_values != "" ? [
    file(var.prometheus_values)
  ] : []

  # Ожидание готовности кластера
  depends_on = [null_resource.wait_for_cluster]
}

# Установка ingress-nginx
resource "helm_release" "ingress_nginx" {
  name              = "ingress-nginx"
  repository        = "https://kubernetes.github.io/ingress-nginx"
  chart             = "ingress-nginx"
  namespace         = "ingress-nginx"
  create_namespace  = true
  wait              = false
  timeout           = 60
  
  set {
    name  = "controller.service.nodePorts.http"
    value = var.ingress_http_nodeport
  }

  set {
    name  = "controller.replicaCount"
    value = var.ingress_replicaCount
  }

  values = var.ingress_values != "" ? [
    file(var.ingress_values)
  ] : []

  depends_on = [helm_release.prometheus_stack]
}

# Установка gitlab-runner
resource "helm_release" "gitlab_runner" {
  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  namespace  = "gitlab-runner"
  create_namespace = true

  set {
    name  = "gitlabUrl"
    value = var.gitlab_url
  }

  set {
    name  = "runnerRegistrationToken"
    value = var.gitlab_runner_token
  }

  values = [
    file("${path.module}/values/runner.yaml")
  ]

  depends_on = [helm_release.ingress_nginx]
}

# Получение манифеста из GitLab
data "http" "diplom_yaml" {
  url = local.diplom_yaml_url
  
  retry {
    attempts     = 3
    min_delay_ms = 1000
    max_delay_ms = 5000
  }
  
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to fetch YAML from GitLab. Status code: ${self.status_code}, URL: ${local.diplom_yaml_url}"
    }
  }
}

# Ожидание готовности ingress-nginx controller
resource "null_resource" "wait_for_ingress" {
  depends_on = [helm_release.ingress_nginx]
  
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Ожидание запуска ingress-nginx..."
      kubectl --kubeconfig=${local.kubeconfig_path} wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
      echo "ingress-nginx готов!"
      sleep 30
    EOT
  }
}

# Применение манифеста дипломного приложения
locals {
  diplom_documents = split("---", local.modified_diplom_yaml)
  
  # Создаем список ресурсов из YAML документов (исключаем пустые строки)
  diplom_resources = [for doc in local.diplom_documents : 
    trimspace(doc) if length(trimspace(doc)) > 0
  ]
}

# Создаем все ресурсы через kubectl_manifest
resource "kubectl_manifest" "diplom_app" {
  count = length(local.diplom_resources)
  
  yaml_body = local.diplom_resources[count.index]
  
  depends_on = [
    helm_release.ingress_nginx,
    null_resource.wait_for_ingress
  ]
}