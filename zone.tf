variable "zones"  {}

variable "ssh_ip1"	{}
variable "ssh_ip2"	{}
variable "ssh_ip3"	{}
variable "ssh_ip4"	{}




resource "ibm_is_subnet" "subnet" {
    count = length(var.zones)
    name = "${var.resource_group}-${var.zones[count.index]}-sn"
    vpc = ibm_is_vpc.vpc.id
    zone = var.zones[count.index]
    resource_group = data.ibm_resource_group.res_grp.id
    network_acl = ibm_is_network_acl.acl.id
    total_ipv4_address_count = 128
}

resource "ibm_is_network_acl" "acl" {
  name		= "${var.resource_group}-${var.region}-acl"
  vpc		= ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.res_grp.id

# Allow all out bound from internal host
  rules {
    name        = "outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }

  rules {
    name        = "http-in"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min = 80
      port_max = 80
    }
  }

  rules {
    name        = "https-in"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min = 443
      port_max = 443
    }
  }

# Ping echo reply
  rules {
    name        = "icmp-in"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    icmp {
      code = 0
      type = 0
    }
  }

# echo 
  rules {
    name        = "icmp-in2"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    icmp {
      code = 0
      type = 8
    }
  }

# workaround: count does not work in rules
  rules {
    name        = "ssh-in1"
    action      = "allow"
    source      = var.ssh_ip1
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min = 22
      port_max = 22
   }
  }

 rules {
   name        = "ssh-in2"
   action      = "allow"
   source      = var.ssh_ip2
   destination = "0.0.0.0/0"
   direction   = "inbound"
   tcp {
     port_min = 22
     port_max = 22
  }
 }

 rules {
   name        = "ssh-in3"
   action      = "allow"
   source      = var.ssh_ip3
   destination = "0.0.0.0/0"
   direction   = "inbound"
   tcp {
     port_min = 22
     port_max = 22
  }
 }

 rules {
   name        = "ssh-in4"
   action      = "allow"
   source      = var.ssh_ip4
   destination = "0.0.0.0/0"
   direction   = "inbound"
   tcp {
     port_min = 22
     port_max = 22
  }
 }

# Since FW is stateless, allow high ports packets back inbound for ports opened by the internal host
  rules {
    name        = "tcp-high-ports"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    tcp {
      port_min = 1024
      port_max = 65535
   }
  }

  rules {
    name        = "udp-high-ports"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    udp {
      port_min = 1024
      port_max = 65535
   }
  }

}
