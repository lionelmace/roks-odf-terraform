# Security Groups
##############################################################################

# Rules required to allow necessary inbound traffic to your cluster (IKS/OCP)
##############################################################################
# To expose apps by using load balancers or Ingress, allow traffic through VPC 
# load balancers. For example, for Ingress listening on TCP/443
resource "ibm_is_security_group_rule" "sg-rule-inbound-icmp" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

# Allow incoming ICMP packets (Ping)
##############################################################################
resource "ibm_is_security_group_rule" "sg-rule-inbound-https" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

# SSH Inbound Rule
##############################################################################
resource "ibm_is_security_group_rule" "sg-rule-inbound-ssh" {
  group     = ibm_is_vpc.vpc.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}