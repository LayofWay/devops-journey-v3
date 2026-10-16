terraform {
  required_providers {
    twc = {
      source = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
    }
  }
}

provider "twc" {
  token = "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCIsImtpZCI6IjFrYnhacFJNQGJSI0tSbE1xS1lqIn0.eyJ1c2VyIjoiaW8zNDYyMjMiLCJ0eXBlIjoiYXBpX2tleSIsImFwaV9rZXlfaWQiOiJlN2FmYjk3MS03ZDViLTRmZWQtYjAxZi0yOGFjOTUyMjk0ZjYiLCJpYXQiOjE3OTE5ODE4NTR9.Vhi4wOz_5K1u5UU27SqyFyLQnkXaBxb2iyIeC_AAT0mhMTOMdGZDodWTeaYXqEk-kyp1652he5REhlRbZX-RCSu3l6e9GjGMrZ4hY1p5WWy5dxsxDSiFDPJBfE1CIUpwl64JCIphOqcv9mNSoNMgh2-pzxTzlzjTop-BQjlErX4YA7i5LY5qPp00Xzsji7fiO--zyk93L9T3PYo_7-rtnXT4-0U4yBPwG0TE7d5GvBx8psmD__WfEtPc4injRm2gkLUFwD6zVJZLIK7n56uOodI5yIUiETY-i7zRCpW1O8okR4adtBEp1wF-W9_vSA_1mvnAT7PH3YDXYbx0-Q4vhYda1aaNG6ptuu-RsU-e05yS_CrrvmEb75sy6vxCAbPM8D6BcirxIogsCiuBBj-aVtgPvakxfski8ALHq65jVHn-GfgWdK3EwSCX7PhPsJW1HWAnnbWINbVqt-vWkn6XOeaRHgwNab1XorxqgkJoGGW4nf7sTVqzcyhJ-ctgj5Hm"
}

# 1. Пресет для мастер-ноды
data "twc_k8s_preset" "master-preset" {
  cpu  = 2
  type = "master"
}

# 2. Создаем Managed Kubernetes кластер
resource "twc_k8s_cluster" "devops-cluster" {
  project_id  = 3040501
  name        = "devops-journey-mks"
  description = "Учебный кластер для DevOps Journey"

  # 🔥 Пробуем формат без "v" и ".0". Если не сработает, мы просто удалим эту строку.
  version        = "v1.34.11+k0s.0"
  network_driver = "flannel"

  # 🔥 Возвращаем старый параметр. Warning можно игнорировать, он не ломает план.
  high_availability = false

  preset_id = data.twc_k8s_preset.master-preset.id
}

# 3. Пресет для рабочих нод
data "twc_k8s_preset" "worker-preset" {
  cpu  = 2
  type = "worker"
}

# 4. Создаем группу рабочих нод
resource "twc_k8s_node_group" "devops-nodes" {
  cluster_id = twc_k8s_cluster.devops-cluster.id
  name       = "devops-node-group"

  preset_id  = data.twc_k8s_preset.worker-preset.id
  node_count = 2

  is_autohealing = true
}

# 5. Выводим полезную информацию
output "cluster_id" {
  value = twc_k8s_cluster.devops-cluster.id
}

output "success_message" {
  value = "🎉 Кластер успешно создан! Теперь можно скачать kubeconfig из панели Timeweb."
}
