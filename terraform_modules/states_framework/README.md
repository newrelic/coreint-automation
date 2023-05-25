# States Framework

The states framework deploys 2 resources:
* An S3 bucket to save state files from the different canaries
* A DynamoDB table to lock deployments

As this module create resources needed by all the other modules/frameworks it has to be run prior to any other deployment. It only needs to ber run once

### Usage:
  ```
  $ terraform init
  
  $ terraform plan
  
  $ terraform apply
  ```
