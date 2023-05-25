terraform {
  required_providers {
    aws   = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }

  backend s3 {
    bucket         = "coreint-canaries"
    dynamodb_table = "coreint-canaries"
    # key            = "" # set the key where the state for this canary will be saved i.e "canary_name/terraform-states-backend.tfstate"
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
      "purpose"     = "Coreint Canaries"
    }
  }
}

# Variables so we can change them using Environment variables.
variable aws_region {
  type    = string
  default = "eu-west-1"
}
