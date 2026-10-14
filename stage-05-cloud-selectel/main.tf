# 1. Указываем провайдер Selectel
terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 5.0"
    }
  }
}

# 2. Настраиваем провайдер
provider "selectel" {
  token      = "TcqGePN9aLiOZjCp7IEPnF1p7_717515"
  project_id = "a9d50be6f2af45618cfe04c22a6786ae"
}

# 3. Простая проверка связи
output "connection_success" {
  value = "✅ Terraform успешно подключился к Selectel! Project ID: a9d50be6f2af45618cfe04c22a6786ae"
}
