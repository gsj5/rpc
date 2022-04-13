# Docs @ https://cloud.ibm.com/docs/terraform?topic=terraform-infrastructure-resources 
#

variable "vm_profiles"	  {}
variable "hostnames"	  {}
variable "disk_sizes"	  {}
variable "disk_profiles"	  {}
variable "vm_image_name"  {}
variable "runcmd"  {}
variable "ssh_pub_key_name" {}

data "ibm_is_image"       "vm_image"	{ name = var.vm_image_name }
data "ibm_is_ssh_key"     "admin_key"	{ name = var.ssh_pub_key_name }


resource "ibm_is_instance" "vm" {
	count	= length(var.hostnames)
	name	= var.hostnames[count.index]
	vpc	= ibm_is_vpc.vpc.id
	zone	= var.zones[count.index]
	profile	= var.vm_profiles[count.index]
	image	= data.ibm_is_image.vm_image.id
	keys	= [data.ibm_is_ssh_key.admin_key.id]
	boot_volume  { name = "${var.hostnames[count.index]}-boot" }
	volumes = [ibm_is_volume.vol[count.index].id]
	resource_group = data.ibm_resource_group.res_grp.id
	primary_network_interface {
		name		= "eth0"
		subnet		= ibm_is_subnet.subnet[count.index].id
		security_groups = [ ibm_is_security_group.allow-in-rnode.id,
				    ibm_is_security_group.allow-in-rnode-propose.id,
				    ibm_is_security_group.allow-in-ssh.id ]
	}
	user_data = data.template_cloudinit_config.cloud-init-vm.rendered
}

resource "ibm_is_volume" "vol" {
	count	= length(var.hostnames)
	name	= "${var.hostnames[count.index]}-data"
	profile	= var.disk_profiles[count.index]
	zone	= var.zones[count.index]
	capacity= var.disk_sizes[count.index]
	resource_group = data.ibm_resource_group.res_grp.id
}

resource "ibm_is_floating_ip" "fip"  {
	count	= length(var.hostnames)
	name	= "${var.hostnames[count.index]}-fip"
	target	= ibm_is_instance.vm[count.index].primary_network_interface.0.id
	resource_group = data.ibm_resource_group.res_grp.id
}

data "template_cloudinit_config" "cloud-init-vm" {
	base64_encode = false
	gzip          = false

	part {
		content = <<EOF
#cloud-config
package-update: true
package_upgrade: true

runcmd:
- var.runcmd

power_state:
 mode: reboot
 message: Rebooting server now.
 timeout: 30
 condition: True
 EOF
	}
}

output "vm_name_ip" {
	#count   = length(var.hostnames)
	#value = "${zipmap(ibm_is_instance.vm[count.index].*.name, ibm_is_floating_ip.fip[count.index].*.address)}"
	value = "${zipmap(ibm_is_instance.vm[0].*.name, ibm_is_floating_ip.fip[0].*.address)}"
}
