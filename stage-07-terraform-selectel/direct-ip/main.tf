locals {
  nodes = {
    "master"   = { name = "k3s-master", vcpus = 2, ram = 2048 }
    "worker-1" = { name = "k3s-worker-1", vcpus = 2, ram = 2048 }
    "worker-2" = { name = "k3s-worker-2", vcpus = 2, ram = 2048 }
  }
}

resource "openstack_compute_keypair_v2" "key" {
  name       = "k3s-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "openstack_compute_flavor_v2" "flavor" {
  for_each  = local.nodes
  name      = "${each.value.name}-flavor"
  vcpus     = each.value.vcpus
  ram       = each.value.ram
  disk      = 0
  is_public = false
}

# --- Security Group ---
resource "openstack_networking_secgroup_v2" "k3s" {
  name        = "k3s-sg"
  description = "k3s cluster access"
}

resource "openstack_networking_secgroup_rule_v2" "tcp_ports" {
  for_each          = toset(["22", "80", "443", "6443"])
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = tonumber(each.value)
  port_range_max    = tonumber(each.value)
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k3s.id
}

resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.k3s.id
  security_group_id = openstack_networking_secgroup_v2.k3s.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k3s.id
}

# 🌐 Прямой публичный IP (public port) — как вкладка "Прямые публичные IP-адреса"
resource "selectel_vpc_public_port_v1" "port" {
  for_each           = local.nodes
  project_id         = var.project_id
  region             = var.region
  security_group_ids = [openstack_networking_secgroup_v2.k3s.id]
}

data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true
  visibility  = "public"
}

resource "openstack_blockstorage_volume_v3" "boot" {
  for_each             = local.nodes
  name                 = "${each.value.name}-boot"
  size                 = 10
  image_id             = data.openstack_images_image_v2.ubuntu.id
  volume_type          = var.volume_type
  availability_zone    = var.availability_zone
  enable_online_resize = true
  lifecycle { ignore_changes = [image_id] }
}

resource "openstack_compute_instance_v2" "node" {
  for_each          = local.nodes
  name              = each.value.name
  flavor_id         = openstack_compute_flavor_v2.flavor[each.key].id
  key_pair          = openstack_compute_keypair_v2.key.name
  availability_zone = var.availability_zone
  network {
    port = selectel_vpc_public_port_v1.port[each.key].id
    uuid = selectel_vpc_public_port_v1.port[each.key].network_id
    name = "network"
  }
  block_device {
    uuid             = openstack_blockstorage_volume_v3.boot[each.key].id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }
  vendor_options { ignore_resize_confirmation = true }
  lifecycle { ignore_changes = [image_id] }
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.ini.tpl", {
    master_ip       = selectel_vpc_public_port_v1.port["master"].ip_address
    worker1_ip      = selectel_vpc_public_port_v1.port["worker-1"].ip_address
    worker2_ip      = selectel_vpc_public_port_v1.port["worker-2"].ip_address
    ssh_private_key = var.ansible_ssh_private_key_path
  })
  filename = "../../stage-06-self-managed-k3s/ansible/inventory.ini"
}

output "master_ip" { value = selectel_vpc_public_port_v1.port["master"].ip_address }
output "worker1_ip" { value = selectel_vpc_public_port_v1.port["worker-1"].ip_address }
output "worker2_ip" { value = selectel_vpc_public_port_v1.port["worker-2"].ip_address }
