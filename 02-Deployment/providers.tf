terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "glubuchik-diplom"
    key        = "diplom/terraform.tfstate"
    region     = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.169.0"
    }
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "~> 2.0"
    # }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "~> 2.0"
    # }
    # kubectl = {
    #   source  = "gavinbunney/kubectl"
    #   version = "~> 1.14"
    # }
  }
  required_version = ">1.8.4"
}

provider "yandex" {
  cloud_id                  = var.cloud_id
  folder_id                 = var.folder_id
  zone                      = var.default_zone
  service_account_key_file  = file("~/.sa-diplom-key1.json")
}

# provider "helm" {
#   kubernetes {
#     config_path = "${path.module}/../kubespray/inventory/mycluster/artifacts/admin.conf"
#   }
# }

# provider "kubernetes" {
#   config_path = "${path.module}/../kubespray/inventory/mycluster/artifacts/admin.conf"
# }

# provider "kubectl" {
#   config_path = "${path.module}/../kubespray/inventory/mycluster/artifacts/admin.conf"
# }