# Usage (Ubuntu 20.04 host)

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip
unzip terraform_0.13.4_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

Install the [terraform libvirt provider](https://github.com/dmacvicar/terraform-provider-libvirt):

```bash
wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.2/terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.Ubuntu_18.04.amd64.tar.gz
tar xf terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.Ubuntu_18.04.amd64.tar.gz
install -d ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
install terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64/
rm terraform-provider-libvirt terraform-provider-libvirt-*.amd64.tar.gz
```

Or install it from source:

```bash
sudo apt-get install -y libvirt-dev
git clone https://github.com/dmacvicar/terraform-provider-libvirt.git
cd terraform-provider-libvirt
make
install -d ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64
install terraform-provider-libvirt ~/.local/share/terraform/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.2/linux_amd64/
cd ..
```

Launch this example:

```bash
terraform init
terraform plan -out=tfplan
time terraform apply tfplan
ssh-keygen -f ~/.ssh/known_hosts -R "$(terraform output ip)"
ssh "vagrant@$(terraform output ip)"
time terraform destroy -force
```

**NB** if you have errors alike `Could not open '/var/lib/libvirt/images/terraform_example_root.img': Permission denied'` you need to reconfigure libvirt by setting `security_driver = "none"` in `/etc/libvirt/qemu.conf` and restart libvirt with `sudo systemctl restart libvirtd`.
