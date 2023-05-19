terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "2.3.2"
    }
  }

  backend s3 {
    bucket         = "nr-coreint-canaries-tfstates"
    dynamodb_table = "nr-coreint-canaries-tflocking"
    key            = "base-framework/global-state-store.tfstate"
    region         = "eu-west-1"
  }
}

# ########################################### #
#  Local file                                 #
# ########################################### #
provider local {}

# ########################################### #
#  TLS certs                                  #
# ########################################### #
provider tls {}

# ########################################### #
#  Cloudinit                                  #
# ########################################### #
provider cloudinit {}

# ########################################### #
#  AWS                                        #
# ########################################### #
provider aws {
  default_tags {
    tags = {
      "owning_team" = "COREINT"
      "purpose"     = "development-integration-environments"
    }
  }
}

data aws_region current {}