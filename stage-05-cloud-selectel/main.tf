terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 5.0"
    }
  }
}

# 🔥 Возвращаем токен и project_id напрямую (для простоты обучения)
provider "selectel" {
  domain_name = "717515"                 # 🔥 Например, "123456"
  username    = "terraform-user"         # 🔥 Имя сервисного пользователя
  password    = "DevOps2024!Selectel144" # 🔥 Пароль сервисного пользователя
  project_id  = "a9d50be6f2af45618cfe04c22a6786ae"
}

# 1. Создаем сам кластер Kubernetes (Control Plane)
resource "selectel_mks_cluster_v1" "devops-cluster" {
  project_id   = "a9d50be6f2af45618cfe04c22a6786ae"
  region       = "ru-8"
  name         = "devops-journey-mks"
  kube_version = "1.35"

  enable_autorepair                 = true
  zonal                             = true
  enable_patch_version_auto_upgrade = false # 🔥 ДОБАВЬ ЭТУ СТРОКУ
}

# 2. Создаем группу рабочих нод (ИСПРАВЛЕННЫЙ СИНТАКСИС)
resource "selectel_mks_nodegroup_v1" "devops-nodes" {
  project_id = "a9d50be6f2af45618cfe04c22a6786ae"
  region     = "ru-8"
  cluster_id = selectel_mks_cluster_v1.devops-cluster.id

  # 🔥 ИСПРАВЛЕННЫЕ ПАРАМЕТРЫ (на основе ошибок Terraform):
  nodes_count                  = 2
  availability_zone            = "ru-8a" # Зона доступности в регионе ru-3
  install_nvidia_device_plugin = false   # Нам не нужны GPU

  # Характеристики нод
  cpus        = 2
  ram_mb      = 4096
  volume_gb   = 30
  volume_type = "universal"

  depends_on = [selectel_mks_cluster_v1.devops-cluster]
}

# 3. Выводим полезную информацию
output "cluster_id" {
  value = selectel_mks_cluster_v1.devops-cluster.id
}
