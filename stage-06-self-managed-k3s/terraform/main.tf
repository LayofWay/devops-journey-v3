# main.tf
terraform {
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 5.0"
    }
  }
}

provider "selectel" {
  domain_name = "717515"                 # Твой ID аккаунта
  username    = "terraform-user"         # Твой сервисный пользователь
  password    = "DevOps2024!Selectel144" # Твой пароль
  project_id  = "a9d50be6f2af45618cfe04c22a6786ae"
}

# Базовые переменные (ПОДСТАВЬ СВОИ ID ИЗ КОНСОЛИ SELECTEL, ЕСЛИ ЭТИ НЕ СРАБОТАЮТ)
# flavor_id "1001" обычно это 2 vCPU, 2GB RAM. Для k3s этого достаточно для теста.
# image_id для Ubuntu 22.04 в Selectel часто начинается на стандартные ID.
variable "flavor_id" { default = "1001" }
variable "image_id" { default = "8b84d011-5e0c-4e7c-9f0d-3b4e5a6c7d8e" } # ⚠️ ЗАМЕНИ НА РЕАЛЬНЫЙ ID ОБРАЗА UBUNTU ИЗ КОНСОЛИ!

# 1. Мастер-нода
resource "selectel_compute_instance_v2" "k3s-master" {
  name      = "k3s-master"
  flavor_id = var.flavor_id

  network {
    name = "public" # Или имя твоей сети в проекте
  }

  block_device {
    uuid             = var.image_id
    source_type      = "image"
    volume_size      = 30
    boot_index       = 0
    destination_type = "local" # Или "volume", в зависимости от доступности
  }
}

# 2. Рабочая нода 1
resource "selectel_compute_instance_v2" "k3s-worker-1" {
  name      = "k3s-worker-1"
  flavor_id = var.flavor_id

  network {
    name = "public"
  }

  block_device {
    uuid             = var.image_id
    source_type      = "image"
    volume_size      = 30
    boot_index       = 0
    destination_type = "local"
  }
}

# 3. Рабочая нода 2
resource "selectel_compute_instance_v2" "k3s-worker-2" {
  name      = "k3s-worker-2"
  flavor_id = var.flavor_id

  network {
    name = "public"
  }

  block_device {
    uuid             = var.image_id
    source_type      = "image"
    volume_size      = 30
    boot_index       = 0
    destination_type = "local"
  }
}

# Выводим IP-адреса для Ansible
output "master_ip" {
  value = selectel_compute_instance_v2.k3s-master.access_ip_v4
}

output "worker_1_ip" {
  value = selectel_compute_instance_v2.k3s-worker-1.access_ip_v4
}

output "worker_2_ip" {
  value = selectel_compute_instance_v2.k3s-worker-2.access_ip_v4
}
