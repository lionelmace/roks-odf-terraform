##############################################################################
## Global Variables
##############################################################################

#region                = "eu-de" # eu-de for Frankfurt MZR

##############################################################################
## VPC
##############################################################################
vpc_classic_access            = false
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster ROKS
##############################################################################
# openshift_machine_flavor = "bx2.4x16"
openshift_machine_flavor = "bx2.16x64" # ODF Flavors

# Available values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
openshift_wait_till          = "OneWorkerNodeReady"
openshift_update_all_workers = false