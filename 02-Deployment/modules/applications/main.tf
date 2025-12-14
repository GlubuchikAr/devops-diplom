terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Ожидание готовности кластера
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      timeout 600 bash -c 'until kubectl --kubeconfig=${local.kubeconfig_path} get nodes 2>/dev/null; do echo "Waiting for cluster..."; sleep 10; done'
      kubectl --kubeconfig=${local.kubeconfig_path} wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  }
}


resource "null_resource" "run_helm_prometheus" {
  provisioner "local-exec" {
    command = <<-EOT
      helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
        --create-namespace \
        --namespace monitoring \
        --set grafana.adminPassword="4-o7blNIb95"
    EOT
  }
}

resource "null_resource" "ingress-nginx" {
  depends_on = [
    null_resource.run_helm_prometheus
  ]

  provisioner "local-exec" {
    command = <<-EOT
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo update
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.nodePorts.http=30080 \
        --set controller.replicaCount=2
    EOT
  }
}

resource "local_file" "gitlab_runner_values" {
  content = yamlencode(local.gitlab_runner_values)
  filename = "${path.module}/gitlab-runner-values.yaml"
}

resource "null_resource" "gitlab-runner" {
  depends_on = [
    null_resource.ingress-nginx
  ]
  
  triggers = {
    gitlab_runner_values = sha256(jsonencode(local.gitlab_runner_values))
  }
  provisioner "local-exec" {
    command = <<-EOT
      helm repo add gitlab https://charts.gitlab.io
      helm repo update
      helm upgrade --install gitlab-runner gitlab/gitlab-runner \
        --namespace gitlab-runner \
        --create-namespace \
        --version 0.70.0 \
        --set revisionHistoryLimit=3 \
        --set gitlabUrl="${var.gitlab_url}" \
        --set runnerRegistrationToken="${var.gitlab_runner_token}" \
        --set rbac.create=true \
        --set serviceAccount.create=true \
        --set serviceAccount.name=gitlab-runner \
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

# # Установка kube-prometheus-stack для мониторинга
# resource "helm_release" "prometheus_stack" {
#   depends_on = [null_resource.wait_for_cluster]

#   name       = "monitoring"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart      = "kube-prometheus-stack"
#   namespace  = "monitoring"
#   create_namespace = true
#   version    = var.kube_prometheus_stack_version

#   values = [
#     yamlencode(local.prometheus_values)
#   ]
# }

# # Установка ingress-nginx для доступа к мониторингу и приложению
# resource "helm_release" "ingress_nginx" {
#   depends_on = [helm_release.prometheus_stack]

#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   create_namespace = true
#   version    = var.ingress-nginx_version
#   values = [
#     yamlencode(local.ingress_nginx_values)
#   ]
# }

# # Установка gitlab-runner
# resource "helm_release" "gitlab_runner" {
#   # depends_on = [null_resource.wait_for_ingress]

#   name       = "gitlab-runner"
#   repository = "https://charts.gitlab.io"
#   chart      = "gitlab-runner"
#   namespace  = "gitlab-runner"
#   create_namespace = true
#   version    = var.gitlab-runner_version
  
#   values = [
#     yamlencode(local.gitlab_runner_values)
#   ]
# }

# # 4. Развертывание приложения
# resource "kubectl_manifest" "diplom_app" {

#   yaml_body = local.modified_diplom_yaml

#   # Проверка успешного развертывания
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Проверка развертывания приложения..."
#       kubectl --kubeconfig=${local.kubeconfig_path} wait \
#         --for=condition=available \
#         --timeout=300s \
#         deployment -l app=diplom-app
#     EOT
#   }
# }


