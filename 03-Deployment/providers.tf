terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "glubuchik-diplom"
    key        = "deployment/terraform.tfstate"
    region     = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.2"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "kubectl" {
  config_path = local.kubeconfig_path
}