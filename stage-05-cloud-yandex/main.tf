# 1. Настройка провайдера
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  cloud_id                 = "standard"
  folder_id                = "b1g93a47mpk3ol2bpq7q"
  zone                     = "ru-central1-a"
  service_account_key_file = "./yc-terraform-key.json"
}

# 2. Проверка подключения
data "yandex_client_config" "current" {}

# 3. 🔥 ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩУЮ СЕТЬ вместо создания новой
# Замени 'enp...' на реальный ID сети из консоли!
data "yandex_vpc_network" "existing" {
  network_id = "enpum8quvovaa15mf695" # 👈 ВСТАВЬ СЮДА ID ИЗ КОНСОЛИ
}

# 4. Создаем подсеть внутри существующей сети
resource "yandex_vpc_subnet" "devops-subnet" {
  name           = "devops-journey-subnet-e" # 🔥 Меняем имя
  zone           = "ru-central1-e"           # 🔥 Меняем зону на 'd'
  network_id     = data.yandex_vpc_network.existing.id
  v4_cidr_blocks = ["10.0.3.0/24"] # 🔥 Меняем диапазон IP
}

# 5. Выводим полезные данные
output "cloud_info" {
  value = "✅ Успешно подключено! Cloud: ${data.yandex_client_config.current.cloud_id}, Folder: ${data.yandex_client_config.current.folder_id}"
}

output "subnet_id" {
  value       = yandex_vpc_subnet.devops-subnet.id
  description = "ID подсети для Kubernetes"
}

output "network_id" {
  value       = data.yandex_vpc_network.existing.id
  description = "ID существующей сети"
}

# 6. Создаем сервисный аккаунт для управления Kubernetes
resource "yandex_iam_service_account" "k8s-sa" {
  name        = "k8s-service-account"
  description = "Сервисный аккаунт для управления Kubernetes кластером"
}

# 7. Назначаем роль "редактор" для сервисного аккаунта (чтобы он мог управлять кластером)
resource "yandex_resourcemanager_folder_iam_member" "k8s-editor" {
  folder_id = "b1g93a47mpk3ol2bpq7q"
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"

  depends_on = [yandex_iam_service_account.k8s-sa]
}

# 8. Создаем Kubernetes кластер
resource "yandex_kubernetes_cluster" "devops-cluster" {
  name        = "devops-journey-cluster"
  description = "Учебный Kubernetes кластер"

  network_id      = data.yandex_vpc_network.existing.id
  release_channel = "REGULAR" # 🔥 Добавляем явный канал

  master {
    zonal {
      zone      = yandex_vpc_subnet.devops-subnet.zone
      subnet_id = yandex_vpc_subnet.devops-subnet.id
    }

    public_ip = true # 🔥 ВАЖНО: делаем мастер-ноду доступной из интернета

    maintenance_policy {
      auto_upgrade = true
    }
  }

  service_account_id      = yandex_iam_service_account.k8s-sa.id
  node_service_account_id = yandex_iam_service_account.k8s-sa.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-editor
  ]
}

# 9. Создаем группу нод (рабочие серверы)
resource "yandex_kubernetes_node_group" "devops-nodes" {
  cluster_id = yandex_kubernetes_cluster.devops-cluster.id
  name       = "devops-node-group"

  instance_template {
    platform_id = "standard-v3"

    resources {
      memory = 2 # 2 ГБ RAM
      cores  = 2 # 2 ядра CPU
    }

    boot_disk {
      type = "network-hdd"
      size = 30 # 30 ГБ диск
    }

    scheduling_policy {
      preemptible = true # 🔥 Прерываемые ноды (дешевле, но могут быть остановлены)
    }

    network_interface {
      nat        = true # Даём доступ в интернет для нод
      subnet_ids = [yandex_vpc_subnet.devops-subnet.id]
    }
  }

  scale_policy {
    fixed_scale {
      size = 2 # 🔥 2 ноды (минимум для отказоустойчивости)
    }
  }

  allocation_policy {
    location {
      zone = yandex_vpc_subnet.devops-subnet.zone
    }
  }

  depends_on = [
    yandex_kubernetes_cluster.devops-cluster
  ]
}

# 10. Выводим информацию для подключения к кластеру
output "kubernetes_cluster_id" {
  value       = yandex_kubernetes_cluster.devops-cluster.id
  description = "ID Kubernetes кластера"
}

output "kubernetes_master_address" {
  value       = yandex_kubernetes_cluster.devops-cluster.master[0].external_v4_address
  description = "Публичный адрес мастер-ноды (для kubectl)"
}
