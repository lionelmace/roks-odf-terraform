##############################################################################
## Global Variables
##############################################################################

#region     = "eu-de"     # eu-de for Frankfurt MZR
#icr_region = "de.icr.io"

##############################################################################
## VPC
##############################################################################
vpc_classic_access            = false
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster ROKS
##############################################################################
openshift_version = "4.19_openshift"
openshift_os      = "RHCOS"
openshift_machine_flavor = "bx2.16x64" # ODF Flavors

# Available values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
openshift_wait_till          = "OneWorkerNodeReady"
openshift_update_all_workers = false

openshift_disable_public_service_endpoint = false
# Secure By default - Public outbound access is blocked as of OpenShift 4.15
# Protect network traffic by enabling only the connectivity necessary 
# for the cluster to operate and preventing access to the public Internet.
# By default, value is false.
openshift_disable_outbound_traffic_protection = true


##############################################################################
## COS
##############################################################################
cos_plan   = "standard"
cos_region = "global"


##############################################################################
## Observability: Monitoring (Sysdig)
##############################################################################

sysdig_plan                    = "graduated-tier"
sysdig_enable_platform_metrics = false
