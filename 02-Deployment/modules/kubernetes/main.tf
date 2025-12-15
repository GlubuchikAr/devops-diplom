# Установка Python и зависимостей
resource "null_resource" "install_python_and_deps" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      # Установка Python и pip, если их нет
      if ! command -v python3 &> /dev/null; then
        echo "Установка Python3..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
      fi
      
      # Создаем виртуальное окружение для Ansible
      if [ ! -d "${path.module}/venv" ]; then
        python3 -m venv "${path.module}/venv"
      fi
      
      # Активируем venv и устанавливаем зависимости
      . "${path.module}/venv/bin/activate"
      pip3 install --upgrade pip3
      ${join(" && \\\n      pip3 install ", var.pip3_install)}
      
      # Проверяем установку
      ansible --version
    EOT
  }
  
  triggers = {
    dependencies_updated = sha256(join(",", var.pip3_install))
  }
}

# Скачивание Kubespray
resource "null_resource" "download_kubespray" {
  depends_on = [null_resource.install_python_and_deps]
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      echo "Активируем виртуальное окружение..."
      . "${path.module}/venv/bin/activate"

      KUBESPRAY_DIR="${path.module}/kubespray"
      
      if [ ! -d "$KUBESPRAY_DIR" ]; then
        echo "Клонирование Kubespray..."
        git clone https://github.com/kubernetes-sigs/kubespray.git "$KUBESPRAY_DIR"
      fi
      
      cd $KUBESPRAY_DIR

      # Копируем пример инвентаря
      if [ ! -d "inventory/mycluster" ]; then
        cp -rfp inventory/sample inventory/mycluster
      fi

      pip3 install -r requirements.txt
      
      echo "Kubespray готов к использованию"
    EOT
  }
}

# Запуск kubespray для настройки K8S кластера
resource "null_resource" "run_kubespray" {
  depends_on = [
    null_resource.download_kubespray
  ]

  triggers = {
    hosts_path = var.hosts_path
    ssh_username = var.ssh_username
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -e  # Выход при ошибке

      # ОЧИСТКА: Удаляем старые файлы блокировки и credentials
      CREDS_DIR="${path.module}/kubespray/inventory/mycluster/credentials"
      if [ -d "$CREDS_DIR" ]; then
        echo "Очищаем каталог credentials..."
        rm -rf "$CREDS_DIR"/*.ansible_lockfile 2>/dev/null || true
        rm -rf "$CREDS_DIR"/*.creds 2>/dev/null || true
        echo "Каталог credentials очищен"
      fi

      echo "Активируем виртуальное окружение..."
      . "${path.module}/venv/bin/activate"

      echo "Копируем inventory файл..."
      cp ${self.triggers.hosts_path} ${path.module}/kubespray/inventory/mycluster/hosts.yaml

      echo "Запускаем Kubespray..."
      cd ${path.module}/kubespray && \
      ansible-playbook -i inventory/mycluster/hosts.yaml \
        -u ${self.triggers.ssh_username} \
        --become --become-user=root \
        -e "kubeconfig_localhost=true" \
        -e "download_timeout=120" \
        cluster.yml \
        --flush-cache
    EOT
  }

  # Очистка при удалении
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Очистка артефактов Kubespray..."
      rm -rf "${path.module}/kubespray/inventory/mycluster/artifacts" 2>/dev/null || true
      rm -rf "${path.module}/kubespray/inventory/mycluster/credentials" 2>/dev/null || true
    EOT
  }
}

