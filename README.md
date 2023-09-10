# Usage (Ubuntu 22.04 host)

Create and install the [base Ubuntu 22.04 vagrant box](https://github.com/rgl/ubuntu-vagrant).

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

Create the infrastructure:

```bash
terraform init
terraform plan -out=tfplan
time terraform apply tfplan
```

**NB** if you have errors alike `Could not open '/var/lib/libvirt/images/terraform_example_root.img': Permission denied'` you need to reconfigure libvirt by setting `security_driver = "none"` in `/etc/libvirt/qemu.conf` and restart libvirt with `sudo systemctl restart libvirtd`.

Show information about the libvirt/qemu guest:

```bash
virsh dumpxml terraform_example
virsh qemu-agent-command terraform_example '{"execute":"guest-info"}' --pretty
virsh qemu-agent-command terraform_example '{"execute":"guest-network-get-interfaces"}' --pretty
./qemu-agent-guest-exec terraform_example id
./qemu-agent-guest-exec terraform_example uname -a
ssh-keygen -f ~/.ssh/known_hosts -R "$(terraform output --raw ip)"
ssh "vagrant@$(terraform output --raw ip)"
```

Destroy the infrastructure:

```bash
time terraform destroy -auto-approve
```

# Virtual BMC

You can externally control the VM using the following terraform providers:

* [vbmc terraform provider](https://registry.terraform.io/providers/rgl/vbmc)
  * exposes an [IPMI](https://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface) endpoint.
  * you can use it with [ipmitool](https://github.com/ipmitool/ipmitool).
  * for more information see the [rgl/terraform-provider-vbmc](https://github.com/rgl/terraform-provider-vbmc) repository.
* [sushy-vbmc terraform provider](https://registry.terraform.io/providers/rgl/sushy-vbmc)
  * exposes a [Redfish](https://en.wikipedia.org/wiki/Redfish_(specification)) endpoint.
  * you can use it with [redfishtool](https://github.com/DMTF/Redfishtool).
  * for more information see the [rgl/terraform-provider-sushy-vbmc](https://github.com/rgl/terraform-provider-sushy-vbmc) repository.
