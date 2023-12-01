terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

variable "linode_token" {
}

# Configure the Linode Provider
provider "linode" {
  token = var.linode_token
}

data "linode_profile" "profile" {}

# Create a Linode
resource "linode_instance" "master-node" {
  count            = 3
  label            = "master-node-0${count.index + 1}"
  image            = "linode/ubuntu22.04"
  region           = "eu-central"
  type             = "g6-standard-4"
  authorized_users = [data.linode_profile.profile.username]
  # authorized_keys  = ["ssh-rsa AAAA...Gw== user@example.local"]
  # root_pass       = "ahToo3caigoh"

  group = "master-node"
  tags  = ["master-node"]
  # swap_size  = 256
  private_ip = true
}

resource "linode_instance" "worker-node" {
  count            = 3
  label            = "worker-node-0${count.index + 1}"
  image            = "linode/ubuntu22.04"
  region           = "eu-central"
  type             = "g6-standard-6"
  authorized_users = [data.linode_profile.profile.username]
  # authorized_keys  = ["ssh-rsa AAAA...Gw== user@example.local"]
  # root_pass       = "ahToo3caigoh"

  group = "worker-node"
  tags  = ["worker-node"]
  # swap_size  = 256
  private_ip = true
}

resource "local_file" "inventory" {
  filename = "./inventory.ini"
  content  = <<-EOF
    [master]
    ${join("\n", [for i in range(3) : "0${i + 1}-master-${replace("${linode_instance.master-node[i].ip_address}", ".", "-")}.sslip.io ansible_ssh_user='root' ansible_ssh_common_args='-o StrictHostKeyChecking=no'"])}

    [worker]
    ${join("\n", [for i in range(3) : "0${i + 1}-worker-${replace("${linode_instance.worker-node[i].ip_address}", ".", "-")}.sslip.io ansible_ssh_user='root' ansible_ssh_common_args='-o StrictHostKeyChecking=no'"])}
  EOF
}
