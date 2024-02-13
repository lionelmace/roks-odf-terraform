
# OpenShift Variables
##############################################################################

variable "openshift_secondary_cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "roks-secondary"
}

variable "openshift_secondary_version" {
  description = "The OpenShift version that you want to set up in your cluster."
  type        = string
  default     = ""
}

variable "openshift_secondary_machine_flavor" {
  description = " The default flavor of the OpenShift worker node."
  type        = string
  default     = "bx2.4x16"
}

variable "openshift_secondary_worker_nodes_per_zone" {
  description = "The number of worker nodes per zone in the default worker pool."
  type        = number
  default     = 1
}

variable "openshift_secondary_wait_till" {
  description = "specify the stage when Terraform to mark the cluster creation as completed."
  type        = string
  default     = "OneWorkerNodeReady"

  validation {
    error_message = "`openshift_secondary_wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.openshift_secondary_wait_till)
  }
}

variable "openshift_secondary_disable_public_service_endpoint" {
  description = "Boolean value true if Public service endpoint to be disabled."
  type        = bool
  default     = false
}

variable "openshift_secondary_force_delete_storage" {
  description = "force the removal of persistent storage associated with the cluster during cluster deletion."
  type        = bool
  default     = true
}

variable "secondary_kms_config" {
  type    = list(map(string))
  default = []
}

variable "secondary_entitlement" {
  description = "Enable openshift entitlement during cluster creation ."
  type        = string
  default     = "cloud_pak"
}

variable "openshift_secondary_update_all_workers" {
  description = "OpenShift version of the worker nodes is updated."
  type        = bool
  default     = true
}

variable "is_openshift_secondary_cluster" {
  type    = bool
  default = true
}

variable "secondary_worker_pools" {
  description = "List of maps describing worker pools"

  type = list(object({
    pool_name        = string
    machine_type     = string
    workers_per_zone = number
  }))

  default = [
    {
      pool_name        = "dev"
      machine_type     = "bx2.4x16"
      workers_per_zone = 1
      # },
      # {
      #     pool_name        = "odf"
      #     machine_type     = "bx2.16x64"
      #     workers_per_zone = 1
    }
  ]

  validation {
    error_message = "Worker pool names must match the regex `^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$`."
    condition = length([
      for pool in var.secondary_worker_pools :
      false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", pool.pool_name))
    ]) == 0
  }

  validation {
    error_message = "Worker pools cannot have duplicate names."
    condition = length(distinct([
      for pool in var.secondary_worker_pools :
      pool.pool_name
    ])) == length(var.secondary_worker_pools)
  }
}

## Resources
##############################################################################
resource "ibm_container_vpc_cluster" "secondary_roks_cluster" {
  name              = format("%s-%s", local.basename, var.openshift_secondary_cluster_name)
  vpc_id            = ibm_is_vpc.vpc.id
  resource_group_id = ibm_resource_group.group.id
  # Optional: Specify OpenShift version. If not included, 4.14 is used
  kube_version                    = var.openshift_secondary_version == "" ? "4.14_openshift" : var.openshift_secondary_version
  cos_instance_crn                = var.is_openshift_secondary_cluster ? ibm_resource_instance.cos_openshift_secondary_registry[0].id : null
  entitlement                     = var.secondary_entitlement
  force_delete_storage            = var.openshift_secondary_force_delete_storage
  tags                            = var.tags
  disable_public_service_endpoint = var.openshift_secondary_disable_public_service_endpoint
  update_all_workers              = var.openshift_secondary_update_all_workers

  flavor       = var.openshift_secondary_machine_flavor
  worker_count = var.openshift_secondary_worker_nodes_per_zone
  wait_till    = var.openshift_secondary_wait_till

  dynamic "zones" {
    for_each = { for subnet in ibm_is_subnet.subnet : subnet.id => subnet }
    content {
      name      = zones.value.zone
      subnet_id = zones.value.id
    }
  }

  kms_config {
    instance_id      = ibm_resource_instance.key-protect.guid # GUID of Key Protect instance
    crk_id           = ibm_kms_key.key.key_id                 # ID of customer root key
    private_endpoint = true
  }
  depends_on = [
    ibm_iam_authorization_policy.roks-kms
  ]
}

# Additional Worker Pool
##############################################################################
# resource "ibm_container_vpc_worker_pool" "roks_worker_pools" {
#   for_each          = { for pool in var.worker_pools : pool.pool_name => pool }
#   cluster           = ibm_container_vpc_cluster.secondary_roks_cluster.id
#   resource_group_id = ibm_resource_group.group.id
#   worker_pool_name  = each.key
#   flavor            = lookup(each.value, "machine_type", null)
#   vpc_id            = ibm_is_vpc.vpc.id
#   worker_count      = each.value.workers_per_zone

#   dynamic "zones" {
#     for_each = { for subnet in ibm_is_subnet.subnet : subnet.id => subnet }
#     content {
#       name      = zones.value.zone
#       subnet_id = zones.value.id
#     }
#   }
# }


## IAM
##############################################################################
# resource "ibm_iam_access_group_policy" "iam-roks" {
#   access_group_id = ibm_iam_access_group.accgrp.id
#   # Full Access Rights
#   roles = ["Reader", "Writer", "Manager", "Administrator", "Editor", "Operator", "Viewer"]

#   resources {
#     service           = "containers-kubernetes"
#     resource_group_id = ibm_resource_group.group.id
#   }
# }


# Object Storage to backup the OpenShift Internal Registry
##############################################################################
resource "ibm_resource_instance" "cos_openshift_secondary_registry" {
  count             = var.is_openshift_secondary_cluster ? 1 : 0
  name              = join("-", [local.basename, "cos-registry"])
  resource_group_id = ibm_resource_group.group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = var.tags
}


##############################################################################
# Connect Log Analysis Service to cluster
# 
# Integrating Logging requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_logging" "openshift_secondary_log_connect" {
  depends_on       = [module.log_analysis.key_guid]
  cluster          = ibm_container_vpc_cluster.secondary_roks_cluster.id
  instance_id      = module.log_analysis.guid
  private_endpoint = var.log_private_endpoint
}

##############################################################################
# Connect Monitoring Service to cluster
# 
# Integrating Monitoring requires the master node to be 'Ready'
# If not, you will face a timeout error after 45mins
##############################################################################
resource "ibm_ob_monitoring" "openshift_secondary_connect_monitoring" {
  depends_on       = [module.cloud_monitoring.key_guid]
  cluster          = ibm_container_vpc_cluster.secondary_roks_cluster.id
  instance_id      = module.cloud_monitoring.guid
  private_endpoint = var.sysdig_private_endpoint
}

# IAM AUTHORIZATIONS
##############################################################################

# Authorization policy between OpenShift and Key Protect
# Require to encrypt OpenShift with Key in Key Protect
resource "ibm_iam_authorization_policy" "roks-kms" {
  source_service_name         = "containers-kubernetes"
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.key-protect.guid
  roles                       = ["Reader"]
}