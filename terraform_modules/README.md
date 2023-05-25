# Terraform Modules

This repository holds basic framework for deploying canary environments with Terraform.

It includes the following frameworks:

## States Framework
The States Framework creates the initial S3 bucket and DynamoDB Table to hold states files and release locks.

**NOTE:** It only needs to be run once.

Once those 2 resource are built, they will be used by the Base Framework and all other canaries to save their current state and lock each release.

## Base Framework
The Base Framework builds the basic infrastructure where canaries can be deployed. See specific [README](base_framework/README.md) for a list of resources deployed.

## Canary Template
Canary template is a skeleton that can be used to build modules for each specific integration canary.
 