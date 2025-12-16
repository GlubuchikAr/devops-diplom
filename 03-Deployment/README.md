### Разворачивает в K8S кластере приложения (мониторинг, раннер для GitLab, приложение диплома)

- Устанавливает через helm prometheus-community/kube-prometheus-stack.
Можно указать пароль для доступа к Grafana
```
variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  default     = "4-o7blNIb95"
  description = "Grafana admin password"
}
```
можно сконфигурировать указав путь к дополнительному values файлу
```
variable "prometheus_values" {
  type        = string
  default     = ""
  description = "Путь к дополнительному values файлу для kube-prometheus-stack"
}
```

- Устанавливает через helm ingress-nginx/ingress-nginx.
Можно указать порт для доступа к Grafana и диплому
```
variable "ingress_http_nodeport" {
  type        = number
  default     = 30080
  description = "NodePort for HTTP ingress"
}
```
можно сконфигурировать указав путь к дополнительному values файлу
```
variable "ingress_values" {
  type        = string
  default     = ""
  description = "Путь к дополнительному values файлу для ingress-nginx"
}
```

- Устанавливает через helm gitlab/gitlab-runner.
Нужно указать токен для подключения ранера к Gitlab
```
variable "gitlab_runner_token" {
  type        = string
  description = "GitLab Runner registration token"
}
```
Можно сконфигурировать Runner с помощью файла [values/runner.yaml](values/runner.yaml)

- Скачивает из GitLab манифест диплома в зависимости от указанного тега
и сохраняет его в [diplom.yaml](diplom.yaml)
(если тег не указан или равен latest, скачивает и запускает манифест из ветки main, если тег указан скачивается манифест из ветки с указанным тегом и использует для поднятия приложения образ с указанным тегом)
- Устанавливает приложение из diplom.yaml