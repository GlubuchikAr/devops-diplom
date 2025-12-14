variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Grafana admin password"
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

variable "ingress_http_nodeport" {
  type        = number
  default     = 30080
  description = "NodePort for HTTP ingress"
}

variable "kube_prometheus_stack_version" {
  type        = string
  default     = "80.2.0"
  description = "Версия kube_prometheus_stack"
}

variable "ingress-nginx_version" {
  type        = string
  default     = "4.14.1"
  description = "Версия ingress-nginx"
}

variable "gitlab-runner_version" {
  type        = string
  default     = "0.83.3"
  description = "Версия gitlab-runner"
}

variable "diplom_tag" {
  description = "Тег диплома"
  type        = string
  default     = ""
}