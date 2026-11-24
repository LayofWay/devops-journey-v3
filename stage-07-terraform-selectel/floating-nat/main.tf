locals {
  nodes = {
    "master"   = { name = "k3s-master", vcpus = 2, ram = 2038 }
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

resource "openstack_networking_network_v2" "net" {
  name           = "k3s-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "k3s-subnet"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = "192.168.100.0/24"
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

data "openstack_networking_network_v2" "external" {
  external = true
}

resource "openstack_networking_router_v2" "router" {
  name                = "k3s-router"
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "ri" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

data "openstack_images_image_v2" "ubuntu" {
  name        = var.image_name
  most_recent = true
  visibility  = "public"
}

resource "openstack_networking_port_v2" "port" {
  for_each           = local.nodes
  name               = "${each.value.name}-port"
  security_group_ids = [openstack_networking_secgroup_v2.k3s.id]
  network_id         = openstack_networking_network_v2.net.id
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet.id
  }
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
    port = openstack_networking_port_v2.port[each.key].id
  }
  block_device {
    uuid             = openstack_blockstorage_volume_v3.boot[each.key].id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }
  vendor_options { ignore_resize_confirmation = true }
  lifecycle { ignore_changes = [image_id] }
  depends_on = [openstack_networking_router_interface_v2.ri]
}

resource "openstack_networking_floatingip_v2" "fip" {
  for_each = local.nodes
  pool     = "external-network"
}

resource "openstack_networking_floatingip_associate_v2" "assoc" {
  for_each    = local.nodes
  floating_ip = openstack_networking_floatingip_v2.fip[each.key].address
  port_id     = openstack_networking_port_v2.port[each.key].id
  depends_on  = [openstack_networking_router_interface_v2.ri]
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.ini.tpl", {
    master_ip       = openstack_networking_floatingip_v2.fip["master"].address
    worker1_ip      = openstack_networking_floatingip_v2.fip["worker-1"].address
    worker2_ip      = openstack_networking_floatingip_v2.fip["worker-2"].address
    ssh_private_key = var.ansible_ssh_private_key_path
  })
  filename = "../../stage-06-self-managed-k3s/ansible/inventory.ini"
}

output "master_ip" { value = openstack_networking_floatingip_v2.fip["master"].address }
output "worker1_ip" { value = openstack_networking_floatingip_v2.fip["worker-1"].address }
output "worker2_ip" { value = openstack_networking_floatingip_v2.fip["worker-2"].address }

# --- Security Group: доступ к кластеру ---
resource "openstack_networking_secgroup_v2" "k3s" {
  name        = "k3s-sg"
  description = "k3s cluster access"
}

# Снаружи: SSH, HTTP, HTTPS, k3s API
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

# Весь трафик между нодами (внутренняя подсеть) — для k3s/flannel/etcd
resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "192.168.100.0/24"
  security_group_id = openstack_networking_secgroup_v2.k3s.id
}

# ICMP (ping)
resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k3s.id
}
