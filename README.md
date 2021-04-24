# Usage (Ubuntu 20.04 host)

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/0.15.0/terraform_0.15.0_linux_amd64.zip
unzip terraform_0.15.0_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

Install the [terraform libvirt provider](https://github.com/dmacvicar/terraform-provider-libvirt):

```bash
wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Ubuntu_20.04.amd64.tar.gz
tar xf terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Ubuntu_20.04.amd64.tar.gz
install -d ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
install terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64/
rm terraform-provider-libvirt terraform-provider-libvirt-*.amd64.tar.gz
```

Or install it from source:

```bash
sudo apt-get install -y libvirt-dev
git clone https://github.com/dmacvicar/terraform-provider-libvirt.git
cd terraform-provider-libvirt
make
install -d ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
install terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64/
cd ..
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
ssh-keygen -f ~/.ssh/known_hosts -R "$(terraform output --raw ip)"
ssh "vagrant@$(terraform output --raw ip)"
```

Destroy the infrastructure:

```bash
time terraform destroy -auto-approve
```
