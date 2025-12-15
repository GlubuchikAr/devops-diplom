# Ожидание готовности кластера
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      timeout 600 bash -c 'until kubectl --kubeconfig=${local.kubeconfig_path} get nodes 2>/dev/null; do echo "Waiting for cluster..."; sleep 10; done'
      kubectl --kubeconfig=${local.kubeconfig_path} wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  }
}

# Установка kube-prometheus-stack для мониторинга
resource "null_resource" "run_helm_prometheus" {
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${local.kubeconfig_path}
      
      helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
        --create-namespace \
        --namespace monitoring \
        --set grafana.adminPassword="${var.grafana_admin_password}"
    EOT
  }
}

# Установка ingress-nginx для доступа к мониторингу и приложению
resource "null_resource" "ingress-nginx" {
  depends_on = [
    null_resource.run_helm_prometheus
  ]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${local.kubeconfig_path}

      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo update
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.nodePorts.http=${var.ingress_http_nodeport} \
        --set controller.replicaCount=${var.ingress_replicaCount}
    EOT
  }
}

# Установка gitlab-runner
resource "null_resource" "gitlab-runner" {
  depends_on = [
    null_resource.ingress-nginx
  ]
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${local.kubeconfig_path}

      helm repo add gitlab https://charts.gitlab.io
      helm repo update
      helm upgrade --install gitlab-runner gitlab/gitlab-runner \
        --namespace gitlab-runner \
        --create-namespace \
        --set gitlabUrl="${var.gitlab_url}" \
        --set runnerRegistrationToken="${var.gitlab_runner_token}" \
        -f ${path.module}/runner/values.yaml
    EOT
  }
}

# Получение манифеста из GitLab
data "http" "diplom_yaml" {
  url = local.diplom_yaml_url
  
  retry {
    attempts     = 3
    min_delay_ms = 1000
    max_delay_ms = 5000
  }
  
  # Проверка статуса ответа
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to fetch YAML from GitLab. Status code: ${self.status_code}, URL: ${local.diplom_yaml_url}"
    }
  }
}

resource "local_file" "diplom_yaml" {
  content  = local.modified_diplom_yaml
  filename = "${path.module}/diplom.yaml"
}

# Запуск монифеста приложения
resource "null_resource" "diplom-app" {
  depends_on = [
    null_resource.ingress-nginx,
    local_file.diplom_yaml
  ]

  triggers = {
    modified_diplom_yaml = local.modified_diplom_yaml
  }
  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${local.kubeconfig_path}

      # Ждем, пока ingress-nginx-controller будет готов
      echo "Ожидание запуска ingress-nginx..."
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
      
      # Небольшая дополнительная задержка
      sleep 30

      cd ${path.module}/
      kubectl apply -f diplom.yaml
    EOT
  }
}

