terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

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