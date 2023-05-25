terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
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
    bucket         = "coreint-canaries"
    dynamodb_table = "coreint-canaries"
    key            = "foundations/terraform-states-backend.tfstate"
    region         = "eu-west-1"
  }
}

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
