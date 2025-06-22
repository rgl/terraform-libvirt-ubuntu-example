# Usage (Ubuntu 22.04 host)

[![Lint](https://github.com/rgl/terraform-libvirt-ubuntu-example/actions/workflows/lint.yml/badge.svg)](https://github.com/rgl/terraform-libvirt-ubuntu-example/actions/workflows/lint.yml)

Create and install the [base Ubuntu 22.04 UEFI vagrant box](https://github.com/rgl/ubuntu-vagrant).

Install the dependencies:

* [Visual Studio Code](https://code.visualstudio.com).
* [Dev Container plugin](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

Open this directory with the Dev Container plugin.

Open `bash` inside the Visual Studio Code Terminal.

Create the infrastructure:

```bash
export CHECKPOINT_DISABLE=1
export TF_LOG=TRACE
export TF_LOG_PATH="$PWD/terraform.log"
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

List this repository dependencies (and which have newer versions):

```bash
GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN' ./renovate.sh
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
