# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.16.0"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    # see https://github.com/hashicorp/terraform-provider-random
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
    # see https://registry.terraform.io/providers/dmacvicar/libvirt
    # see https://github.com/dmacvicar/terraform-provider-libvirt
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.9"
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
  default = "ubuntu-26.04-uefi-amd64_vagrant_box_image_0.0.0_box_0.img"
}

variable "network_cidr" {
  type    = string
  default = "10.17.4.0/24"
}

# see https://gitlab.com/libosinfo/osinfo-db/-/tree/main/data/os/ubuntu.com/ubuntu-26.04.xml.in
locals {
  os_id = "http://ubuntu.com/ubuntu/${regex("ubuntu-([^-]+)", var.base_volume_name)[0]}"
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/network
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/network.md
resource "libvirt_network" "example" {
  name = var.prefix
  forward = {
    nat = {
      ports = [
        {
          start = 1024
          end   = 65535
        }
      ]
    }
  }
  ips = [
    {
      address = cidrhost(var.network_cidr, 1)
      netmask = cidrnetmask(var.network_cidr)
      dhcp = {
        ranges = [
          {
            start = cidrhost(var.network_cidr, 2)
            end   = cidrhost(var.network_cidr, -2)
          }
        ]
      }
    }
  ]
}

# create a cloud-init cloud-config.
# NB this creates an iso image that will be used by the NoCloud cloud-init datasource.
# see journalctl -u cloud-init
# see /run/cloud-init/*.log
# see https://cloudinit.readthedocs.io/en/latest/topics/examples.html#disk-setup
# see https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html#datasource-nocloud
# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/cloudinit_disk
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/cloudinit_disk.md
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/internal/provider/cloudinit_disk_resource.go#L291-L341
resource "libvirt_cloudinit_disk" "example" {
  name           = "${var.prefix}_example_cloudinit.iso"
  network_config = <<-EOF
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: false
  EOF
  meta_data      = <<-EOF
  EOF
  user_data      = <<-EOF
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
    /dev/disk/by-id/wwn-0x000000000000ab00:
      table_type: gpt
      layout:
        - [100, 83]
      overwrite: false
  fs_setup:
    - label: data
      device: /dev/disk/by-id/wwn-0x000000000000ab00-part1
      filesystem: ext4
      overwrite: false
  mounts:
    - [/dev/disk/by-id/wwn-0x000000000000ab00-part1, /data, ext4, 'defaults,discard,nofail', '0', '2']
  runcmd:
    - sed -i '/vagrant insecure public key/d' /home/vagrant/.ssh/authorized_keys
  EOF
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/volume
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/volume.md
resource "libvirt_volume" "example_cloudinit" {
  pool = "default"
  name = "${var.prefix}-cloudinit.iso"
  create = {
    content = {
      url = libvirt_cloudinit_disk.example.path
    }
  }
}

# this uses the vagrant ubuntu image imported from https://github.com/rgl/ubuntu-vagrant.
# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/volume
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/volume.md
resource "libvirt_volume" "example_root" {
  pool     = "default"
  name     = "${var.prefix}-root.img"
  capacity = 66 * 1024 * 1024 * 1024 # GiB. the root FS is automatically resized by cloud-init growpart (see https://cloudinit.readthedocs.io/en/latest/topics/examples.html#grow-partitions).
  target = {
    format = {
      type = "qcow2"
    }
  }
  backing_store = {
    format = {
      type = "qcow2"
    }
    path = "/var/lib/libvirt/images/${var.base_volume_name}"
  }
}

# a data disk.
# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/volume
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/volume.md
resource "libvirt_volume" "example_data" {
  pool     = "default"
  name     = "${var.prefix}-data.img"
  capacity = 6 * 1024 * 1024 * 1024 # GiB.
  target = {
    format = {
      type = "qcow2"
    }
  }
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/resources/domain
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/resources/domain.md
resource "libvirt_domain" "example" {
  name        = var.prefix
  description = "created from ${path.cwd}"
  running     = true
  type        = "kvm"
  vcpu        = 2
  memory      = 1024
  memory_unit = "MiB"
  features = {
    acpi = true
    apic = {}
    pae  = true
  }
  metadata = {
    xml = <<-EOF
      <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
        <libosinfo:os id="${local.os_id}"/>
      </libosinfo:libosinfo>
      EOF
  }
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
  }
  cpu = {
    mode = "host-passthrough"
  }
  devices = {
    graphics = [
      {
        spice = {
          auto_port = true
          listeners = [
            {
              address = {}
            }
          ]
        }
      }
    ]
    videos = [
      {
        model = {
          type    = "qxl"
          primary = "yes"
          vram    = 65536
          ram     = 65536
          vga_mem = 16384
          heads   = 1
        }
      }
    ]
    controllers = [
      {
        type  = "scsi"
        model = "virtio-scsi"
      },
      {
        type = "virtio-serial"
      }
    ]
    channels = [
      {
        source = {
          unix = {
            mode = "bind"
          }
        }
        target = {
          virt_io = {
            name = "org.qemu.guest_agent.0"
          }
        }
      },
      {
        source = {
          spice_vmc = true
        }
        target = {
          virt_io = {
            name = "com.redhat.spice.0"
          }
        }
      }
    ]
    rngs = [
      {
        model = "virtio"
        backend = {
          random = "/dev/urandom"
        }
      }
    ]
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = libvirt_volume.example_root.pool
            volume = libvirt_volume.example_root.name
          }
        }
        target = {
          bus = "scsi"
          dev = "sda"
        }
        wwn = format("000000000000aa%02x", 0)
      },
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = libvirt_volume.example_data.pool
            volume = libvirt_volume.example_data.name
          }
        }
        target = {
          bus = "scsi"
          dev = "sdb"
        }
        wwn = format("000000000000ab%02x", 0)
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.example_cloudinit.pool
            volume = libvirt_volume.example_cloudinit.name
          }
        }
        target = {
          bus = "scsi"
          dev = "hdd"
        }
        serial = "cloudinit"
      }
    ]
    interfaces = [
      {
        type = "network"
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.example.name
          }
        }
        wait_for_ip = {}
      }
    ]
  }
}

# see https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "example_provision" {
  provisioner "remote-exec" {
    inline = [
      <<-EOF
      #!/usr/bin/bash
      set -eux
      sudo cloud-init --version
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
      mount | grep -E '^/dev/' | sort
      cat /etc/fstab | grep -E '^\s*[^#]' | sort
      df -h
      sudo tune2fs -l "$(findmnt -n -o SOURCE /data)"
      EOF
    ]
    connection {
      type        = "ssh"
      user        = "vagrant"
      host        = data.libvirt_domain_interface_addresses.example.interfaces[0].addrs[0].addr
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

# see https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.9/docs/data-sources/domain_interface_addresses
# see https://github.com/dmacvicar/terraform-provider-libvirt/blob/v0.9.9/docs/data-sources/domain_interface_addresses.md
data "libvirt_domain_interface_addresses" "example" {
  domain = libvirt_domain.example.name
}

output "ip" {
  value = data.libvirt_domain_interface_addresses.example.interfaces[0].addrs[0].addr
}
