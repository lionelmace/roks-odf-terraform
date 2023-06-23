##############################################################################
# IBM Cloud Provider
##############################################################################

terraform {
  required_version = ">=1.3"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.55.0-beta0"
    }
  }
}

provider "ibm" {
  region = var.region
}

##############################################################################