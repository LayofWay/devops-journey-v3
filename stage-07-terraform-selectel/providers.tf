terraform {
  required_version = ">= 1.0.0"

  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 5.0" # Используем актуальную мажорную версию провайдера
    }
  }
}

provider "selectel" {
  token = var.selectel_token
}
