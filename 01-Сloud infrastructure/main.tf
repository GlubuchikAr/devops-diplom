# Создание сервисного аккаунта для Terraform
resource "yandex_iam_service_account" "service" {
  folder_id     = var.folder_id
  name          = var.account_name
  description   = "Service account"
}

# Назначение минимально необходимых ролей
resource "yandex_resourcemanager_folder_iam_member" "vpc-admin" {
  folder_id = var.folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "compute-admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "viewer" {
  folder_id = var.folder_id
  role      = "viewer" # Для просмотра образов (yandex_compute_image)
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "service-keys" {
  service_account_id = yandex_iam_service_account.service.id
  description        = "Static access keys"
}

# Создание бакета с использованием ключа
resource "yandex_storage_bucket" "tf-bucket" {
  access_key = yandex_iam_service_account_static_access_key.service-keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-keys.secret_key
  bucket     = var.bucket_name
  folder_id  = var.folder_id
  anonymous_access_flags {
    read = false
    list = false
  }

  force_destroy = true

# Создание backend.conf для доступа к S3 в основном проэкте
provisioner "local-exec" {
  command = "echo 'access_key = \"${yandex_iam_service_account_static_access_key.service-keys.access_key}\"' > ../backend.conf"
}
provisioner "local-exec" {
  command = "echo 'secret_key = \"${yandex_iam_service_account_static_access_key.service-keys.secret_key}\"' >> ../backend.conf"
}
}

# Создание Авторизованного ключа сервисного аккаунта для использования в основном проэкте
resource "yandex_iam_service_account_key" "sa-auth-key" {
  service_account_id = yandex_iam_service_account.service.id
  description        = "Key for provider auth"
  key_algorithm      = "RSA_4096"
}

resource "local_file" "sa-key-json" {
  filename = pathexpand("~/.sa-diplom-key.json")
  content = jsonencode({
    id                 = yandex_iam_service_account_key.sa-auth-key.id
    service_account_id = yandex_iam_service_account_key.sa-auth-key.service_account_id
    private_key        = yandex_iam_service_account_key.sa-auth-key.private_key
  })
}