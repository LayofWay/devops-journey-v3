terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 8.6.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "selectel" {
  domain_name = var.selectel_account_id
  username    = var.selectel_username
  password    = var.selectel_password
  auth_region = var.region
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
}

provider "openstack" {
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3"
  domain_name = var.selectel_account_id
  tenant_id   = var.project_id
  user_name   = var.selectel_username
  password    = var.selectel_password
  region      = var.region
}
