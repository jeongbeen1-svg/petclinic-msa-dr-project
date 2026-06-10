terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14.0"
    }
  }

  # Azure remote state backend. Create these first, or comment this block for local state.
  backend "azurerm" {
    resource_group_name  = "tf-core-ej-tfstate"
    storage_account_name = "tfcoretfstateej"
    container_name       = "tfstate"
    key                  = "dev/test-azure/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "core"
}

provider "kubernetes" {
  host                   = module.workload.cluster_endpoint
  client_certificate     = base64decode(module.workload.client_certificate)
  client_key             = base64decode(module.workload.client_key)
  cluster_ca_certificate = base64decode(module.workload.cluster_ca)
}

provider "helm" {
  kubernetes = {
    host                   = module.workload.cluster_endpoint
    client_certificate     = base64decode(module.workload.client_certificate)
    client_key             = base64decode(module.workload.client_key)
    cluster_ca_certificate = base64decode(module.workload.cluster_ca)
  }
}
