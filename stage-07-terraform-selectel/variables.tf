variable "selectel_token" {
  description = "Selectel API Token с правами на VPC и Cloud Servers"
  type        = string
  sensitive   = true # Скрывает значение в выводе terraform
}

variable "project_id" {
  description = "ID проекта в Selectel (можно найти в панели управления)"
  type        = string
}

variable "region" {
  description = "Регион Selectel (например, ru-3 для Москвы, ru-7 для Москвы (новый), ru-8 для Санкт-Петербурга)"
  type        = string
  default     = "ru-3"
}

variable "ssh_public_key_path" {
  description = "Путь к твоему публичному SSH ключу на локальной машине"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Измени, если твой ключ называется иначе (например, id_ed25519.pub)
}
