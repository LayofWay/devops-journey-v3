variable "selectel_token" {
  description = "IKB3ok5msHfpxeY8SghxoWYAo_717515"
  type        = string
  sensitive   = true # Скрывает значение в выводе terraform
}

variable "project_id" {
  description = "a9d50be6f2af45618cfe04c22a6786ae"
  type        = string
}

variable "region" {
  description = "Регион Selectel (например, ru-3 для Москвы, ru-7 для Москвы (новый), ru-8 для Санкт-Петербурга)"
  type        = string
  default     = "ru-1"
}

variable "ssh_public_key_path" {
  description = "Путь к твоему публичному SSH ключу на локальной машине"
  type        = string
  default     = "~/.ssh/id_ed25519.pub" # Измени, если твой ключ называется иначе (например, id_ed25519.pub)
}

variable "ansible_ssh_private_key_path" {
  description = "Путь к приватному SSH ключу на локальной машине для Ansible"
  type        = string
  default     = "~/.ssh/id_ed25519" # Измени, если твой ключ называется иначе (например, id_rsa)
}
