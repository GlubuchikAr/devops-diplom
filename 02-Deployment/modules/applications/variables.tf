variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  default     = "4-o7blNIb95"
  description = "Grafana admin password"
}

variable "ingress_http_nodeport" {
  type        = number
  default     = 30080
  description = "NodePort for HTTP ingress"
}

variable "ingress_replicaCount" {
  type        = number
  default     = 2
  description = "ingress replicaCount"
}

variable "gitlab_url" {
  type        = string
  default     = "https://gitlab.com"
  description = "GitLab URL"
}

variable "gitlab_runner_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "GitLab Runner registration token"
}

variable "diplom_tag" {
  description = "Тег диплома"
  type        = string
  default     = ""
}

variable "diplom_host" {
  description = "Host для доступа к странице диплома"
  type        = string
  default     = "diplom.aglubuchik.com"
}

variable "grafana_host" {
  description = "Host для доступа к странице мониторинга"
  type        = string
  default     = "grafana.aglubuchik.com"
}

variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Файл конфигурации для доступа к K8S кластера"
}

# variable "kube_prometheus_stack_version" {
#   type        = string
#   default     = "80.2.0"
#   description = "Версия kube_prometheus_stack"
# }

# variable "ingress-nginx_version" {
#   type        = string
#   default     = "4.14.1"
#   description = "Версия ingress-nginx"
# }

# variable "gitlab-runner_version" {
#   type        = string
#   default     = "0.83.3"
#   description = "Версия gitlab-runner"
# }