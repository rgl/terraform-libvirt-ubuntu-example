# Usage (Ubuntu 18.04)

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/0.12.9/terraform_0.12.9_linux_amd64.zip
unzip terraform_0.12.9_linux_amd64.zip
sudo cp terraform /usr/local/bin
```

Install the [terraform libvirt provider](https://github.com/dmacvicar/terraform-provider-libvirt):

```bash
wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.0/terraform-provider-libvirt-0.6.0+git.1569597268.1c8597df.Ubuntu_18.04.amd64.tar.gz
tar xf terraform-provider-libvirt-0.6.0+git.1569597268.1c8597df.Ubuntu_18.04.amd64.tar.gz
install -d ~/.terraform.d/plugins/linux_amd64
install terraform-provider-libvirt ~/.terraform.d/plugins/linux_amd64/
rm terraform-provider-libvirt
```

Or install it from source:

```bash
sudo apt-get install -y libvirt-dev
git clone https://github.com/dmacvicar/terraform-provider-libvirt.git
cd terraform-provider-libvirt
make
install -d ~/.terraform.d/plugins/linux_amd64
install terraform-provider-libvirt ~/.terraform.d/plugins/linux_amd64/
cd ..
```

Launch this example:

```bash
terraform init
terraform plan
time terraform apply -auto-approve
ssh-keygen -f ~/.ssh/known_hosts -R "$(terraform output ip)"
ssh "vagrant@$(terraform output ip)"
time terraform destroy -force
```

**NB** if you have errors alike `Could not open '/var/lib/libvirt/images/terraform_example_root.img': Permission denied'` you need to reconfigure libvirt by setting `security_driver = "none"` in `/etc/libvirt/qemu.conf` and restart libvirt with `sudo systemctl restart libvirtd`.
