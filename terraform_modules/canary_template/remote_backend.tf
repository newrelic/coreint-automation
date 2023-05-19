data terraform_remote_state base_framework {
  backend = "s3"

  config = {
    bucket         = "nr-coreint-canaries-tfstates"
    dynamodb_table = "nr-coreint-canaries-tflocking"
    key            = "base-framework/global-state-store.tfstate"
    region         = "eu-west-1"
  }
}