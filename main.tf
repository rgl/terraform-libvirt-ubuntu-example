# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.14.3"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    # see https://github.com/hashicorp/terraform-provider-random
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
    # see https://registry.terraform.io/providers/dmacvicar/libvirt
    # see https://github.com/dmacvicar/terraform-provider-libvirt
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "prefix" {
  type    = string
  default = "terraform-ubuntu-example"
}

# NB this uses the vagrant ubuntu image imported from https://github.com/rgl/ubuntu-vagrant.
variable "base_volume_name" {
  type    = string
  default = "ubuntu-24.04-uefi-amd64_vagrant_box_image_0.0.0_box_0.img"
}

# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/website/docs/r/network.markdown
resource "libvirt_network" "example" {
  name      = var.prefix
  mode      = "nat"
  domain    = "example.test"
  addresses = ["10.17.3.0/24"]
  dhcp {
    enabled = false
  }
  dns {
    enabled    = true
    local_only = false
  }
  lifecycle {
    ignore_changes = [
      dhcp[0].enabled, # see https://github.com/dmacvicar/terraform-provider-libvirt/issues/998
    ]
  }
}

# create a cloud-init cloud-config.
# NB this creates an iso image that will be used by the NoCloud cloud-init datasource.
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/website/docs/r/cloudinit.html.markdown
# see journalctl -u cloud-init
# see /run/cloud-init/*.log
# see https://cloudinit.readthedocs.io/en/latest/topics/examples.html#disk-setup
# see https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#datasource-nocloud
# see createISO at https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/libvirt/cloudinit_def.go#L139-L168
resource "libvirt_cloudinit_disk" "example_cloudinit" {
  name      = "${var.prefix}_example_cloudinit.iso"
  user_data = <<-EOF
  #cloud-config
  fqdn: example.test
  manage_etc_hosts: true
  users:
    - name: vagrant
      plain_text_passwd: vagrant
      lock_passwd: false
      ssh_authorized_keys:
        - ${jsonencode(trimspace(file("~/.ssh/id_rsa.pub")))}
  disk_setup:
    /dev/sdb:
      table_type: gpt
      layout:
        - [100, 83]
      overwrite: false
  fs_setup:
    - label: data
      device: /dev/sdb1
      filesystem: ext4
      overwrite: false
  mounts:
    - [/dev/sdb1, /data, ext4, 'defaults,discard,nofail', '0', '2']
  runcmd:
    - sed -i '/vagrant insecure public key/d' /home/vagrant/.ssh/authorized_keys
  EOF
}

# this uses the vagrant ubuntu image imported from https://github.com/rgl/ubuntu-vagrant.
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/website/docs/r/volume.html.markdown
resource "libvirt_volume" "example_root" {
  name             = "${var.prefix}-root.img"
  base_volume_name = var.base_volume_name
  format           = "qcow2"
  size             = 66 * 1024 * 1024 * 1024 # 66GiB. the root FS is automatically resized by cloud-init growpart (see https://cloudinit.readthedocs.io/en/latest/topics/examples.html#grow-partitions).
}

# a data disk.
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/website/docs/r/volume.html.markdown
resource "libvirt_volume" "example_data" {
  name   = "${var.prefix}-data.img"
  format = "qcow2"
  size   = 6 * 1024 * 1024 * 1024 # 6GiB.
}

# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.8.3/website/docs/r/domain.html.markdown
resource "libvirt_domain" "example" {
  name     = var.prefix
  machine  = "q35"
  firmware = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  cpu {
    mode = "host-passthrough"
  }
  vcpu       = 2
  memory     = 1024
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.example_cloudinit.id
  xml {
    xslt = file("libvirt-domain.xsl")
  }
  video {
    type = "qxl"
  }
  disk {
    volume_id = libvirt_volume.example_root.id
    scsi      = true
  }
  disk {
    volume_id = libvirt_volume.example_data.id
    scsi      = true
  }
  network_interface {
    network_id     = libvirt_network.example.id
    wait_for_lease = true
    addresses      = ["10.17.3.2"]
  }
  provisioner "remote-exec" {
    inline = [
      <<-EOF
      #!/usr/bin/bash
      set -eux
      sudo cloud-init schema --system --annotate
      sudo cloud-init status --long --wait
      id
      uname -a
      cat /etc/os-release
      echo "machine-id is $(cat /etc/machine-id)"
      hostname --fqdn
      cat /etc/hosts
      sudo sfdisk -l
      lsblk -x KNAME -o KNAME,SIZE,TRAN,SUBSYSTEMS,FSTYPE,UUID,LABEL,MODEL,SERIAL | cat
      mount | grep ^/dev
      df -h
      EOF
    ]
    connection {
      type        = "ssh"
      user        = "vagrant"
      host        = self.network_interface[0].addresses[0] # see https://github.com/dmacvicar/terraform-provider-libvirt/issues/660
      private_key = file("~/.ssh/id_rsa")
    }
  }
  lifecycle {
    ignore_changes = [
      nvram,
      disk[0].wwn,
      disk[1].wwn,
    ]
  }
}

output "ip" {
  value = length(libvirt_domain.example.network_interface[0].addresses) > 0 ? libvirt_domain.example.network_interface[0].addresses[0] : ""
}
