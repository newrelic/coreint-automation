data terraform_remote_state base_framework {
  backend = "s3"

  config = {
    bucket         = "coreint-canaries"
    dynamodb_table = "coreint-canaries"
    key            = "foundations/terraform-states-backend.tfstate"
    region         = "eu-west-1"
  }
}
