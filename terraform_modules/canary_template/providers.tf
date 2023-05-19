terraform {
  required_providers {
    aws   = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }

  backend s3 {
    bucket         = "nr-coreint-canaries-tfstates"
    dynamodb_table = "nr-coreint-canaries-tflocking"
    key            = "base-framework/integrations/oracle.tfstate"
    region         = "eu-west-1"
  }
}

# ########################################### #
#  AWS                                        #
# ########################################### #
provider aws {
  region  = var.aws_region

  default_tags {
    tags = {
      "owning_team" = "COREINT"
      "purpose"     = "e2e-nightly-automation"
    }
  }
}

# Variables so we can change them using Environment variables.
variable aws_region {
  type    = string
  default = "eu-west-1"
}