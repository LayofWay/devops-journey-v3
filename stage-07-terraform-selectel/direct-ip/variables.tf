variable "selectel_account_id" { type = string }
variable "selectel_username" { type = string }
variable "selectel_password" {
  type      = string
  sensitive = true
}
variable "project_id" { type = string }
variable "region" { type = string }
variable "availability_zone" { type = string }
variable "volume_type" { type = string }
variable "image_name" {
  type    = string
  default = "Ubuntu 26.04 LTS 64-bit"
}
variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
variable "ansible_ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}
