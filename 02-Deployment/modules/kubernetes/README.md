### Разворачивает на подготовленных виртуальных машинах K8S кластер


- Устанавливает python3 на машину, с которой запускается Terraform.
- Создает виртуальное окружение в [kubernetes/venv](02-Deployment/modules/kubernetes/venv)
- Устанавливает через pip3 ansible
- Клонирует https://github.com/kubernetes-sigs/kubespray.git в [kubernetes/kubespray](02-Deployment/modules/kubernetes/kubespray)
- Устанавливает зависимости kubespray
- Переносит указанный в переменной инвентарь в kubespray/inventory/mycluster/hosts.yaml
```
variable "hosts_path" {
  type        = string
  default     = "../compute/inventory/hosts.yaml"
  description = "Путь к файлу hosts.yaml"
}
```
- Запускает 
```
ansible-playbook -i inventory/mycluster/hosts.yaml \
  -u ${self.triggers.ssh_username} \
  --become --become-user=root \
  -e "kubeconfig_localhost=true" \
  -e "download_timeout=120" \
  cluster.yml \
  --flush-cache
```