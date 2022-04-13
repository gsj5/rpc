variable "ibmcloud_api_key" {}
variable "region"           {}
variable "resource_group"   {}
variable "public_in_ports"    {}
variable "proposing_ports"    {}
variable "proposing_ip"    {}
variable "ssh_ips"	    {}

terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.23.2"
    }
  }
}

provider "ibm" {
        ibmcloud_api_key= var.ibmcloud_api_key
        region          = var.region
}


data "ibm_resource_group" "res_grp"     { name = var.resource_group }

# Create gen2 VPC first
resource "ibm_is_vpc" "vpc" {
        name            = "${var.resource_group}-${var.region}-vpc"
        resource_group  = data.ibm_resource_group.res_grp.id
}


#######################  Security Group ##############################################

resource "ibm_is_security_group_rule" "allow_out_all" {
    group = ibm_is_security_group.allow-in-rnode.id
    direction = "outbound"
}

###################################
####### rnode-propose-in-sg #######
###################################

resource "ibm_is_security_group" "allow-in-rnode-propose" {
        name            = "${var.resource_group}-${var.region}-multi-rnode-propose-in-sg"
        vpc             = ibm_is_vpc.vpc.id
        resource_group  = data.ibm_resource_group.res_grp.id
}

# open ports 40402, 41402, 42402... for proposeing host
resource "ibm_is_security_group_rule" "allow_in_rnode_propose_ports1" {
    count = length(var.proposing_ports)
    group = ibm_is_security_group.allow-in-rnode-propose.id
    direction = "inbound"
    remote     = var.proposing_ip
    tcp {
        port_min = var.proposing_ports[count.index]
        port_max = var.proposing_ports[count.index]
    }
}

################################
####### multi-rnode-in-sg ######
################################

resource "ibm_is_security_group" "allow-in-rnode" {
        name            = "${var.resource_group}-${var.region}-multi-rnode-in-sg"
        vpc             = ibm_is_vpc.vpc.id
        resource_group  = data.ibm_resource_group.res_grp.id
}

# open ports 40400, 41400, 42400... & 40401, 41401, 42401...
resource "ibm_is_security_group_rule" "allow_in_rnode_ports" {
    count = length(var.public_in_ports)
    group = ibm_is_security_group.allow-in-rnode.id
    direction = "inbound"
    remote     = "0.0.0.0/0"
    tcp {
        port_min = var.public_in_ports[count.index]
        port_max = var.public_in_ports[count.index]
    }
}

resource "ibm_is_security_group_rule" "allow_in_icmp" {
        group     = ibm_is_security_group.allow-in-rnode.id
        direction = "inbound"
        remote    = "0.0.0.0/0"
        icmp {
                code = 0
                type = 8
        }
}

################################
####### rnode-ssh-in-sg ######
################################

resource "ibm_is_security_group" "allow-in-ssh" {
        name            = "${var.resource_group}-${var.region}-ssh-in-sg"
        vpc             = ibm_is_vpc.vpc.id
        resource_group  = data.ibm_resource_group.res_grp.id
}

resource "ibm_is_security_group_rule" "allow_in_ssh" {
    count = length(var.ssh_ips)
    group = ibm_is_security_group.allow-in-ssh.id
    direction = "inbound"
    remote     = var.ssh_ips[count.index]
    tcp {
        port_min = 22
        port_max = 22
    }
}

