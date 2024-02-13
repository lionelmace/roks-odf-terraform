##############################################################################
# COS Instance with 1 bucket to store your SCC evaluation results
##############################################################################


# COS Variables
##############################################################################
variable "cos_plan" {
  description = "COS plan type"
  type        = string
  default     = "standard"
}

variable "cos_region" {
  description = "Enter Region for provisioning"
  type        = string
  default     = "global"
}

# COS Service for OADP
##############################################################################

resource "ibm_resource_instance" "cos-oadp" {
  name              = format("%s-%s", local.basename, "cos-oadp")
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_region
  resource_group_id = ibm_resource_group.group.id
  tags              = var.tags

  parameters = {
    service-endpoints = "private"
  }
}

## COS Bucket
##############################################################################
resource "ibm_cos_bucket" "bucket-oadp" {
  bucket_name          = format("%s-%s", local.basename, "bucket-oadp")
  resource_instance_id = ibm_resource_instance.cos-oadp.id
  storage_class        = "smart"

  depends_on  = [ibm_iam_authorization_policy.iam-auth-kms-cos]
  kms_key_crn = ibm_kms_key.key.id

  # cross_region_location = "eu"
  region_location      = "eu-de"

  metrics_monitoring {
    usage_metrics_enabled   = true
    request_metrics_enabled = true
    metrics_monitoring_crn  = module.cloud_monitoring.crn
  }
  endpoint_type = "public"
}

resource "ibm_resource_key" "bucket-key" {
  name                 = "bucket-oadp-key"
  resource_instance_id = ibm_resource_instance.cos-oadp.id
  parameters           = { "HMAC" = true }
  role                 = "Object, Reader, Manager"
}

# Authorization policy between COS Bucket (Source) and Key Protect (Target)
# Required to encrypt COS buckets
resource "ibm_iam_authorization_policy" "iam-auth-kms-cos" {
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.cos-oadp.guid
  target_service_name         = "kms"
  target_resource_instance_id = ibm_resource_instance.key-protect.guid
  roles                       = ["Reader"]
}