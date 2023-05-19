# Terraform Modules

This repository holds basic framework for deploying canary environments with Terraform.

## Base Framework

Base framework builds basic infrastructure to deploy canary resources. When applied, terraform will create:
* 1 Main VPC network 
* 1 Public subnet from the main VPC address block
* 3 Private subnets from the main VPC address block (1 in each availability zone)
* 1 Internet Gateway to allow outbound communication
* 1 NAT Gateway to allow outbound communication from resources in the private subnets
* 3 Route Tables (Default, Public and Private)
* 1 Default Security Group allowing all traffic on the VPC
* 1 Bastion EC2 Ubuntu instance (Jump Server) on the public subnet allowing external ICMP and SSH traffic
* TLS Certificate and SSH Key

**IMPORTANT**: All state and locks for this terraform module are held in the S3 bucket and DynamoDB table created by the [states framework](##States-Framework). Therefore, it is important the states_framework module to be run prior to base_framework.

### Usage:
  ```
  $ terraform init
  
  $ terraform plan
  
  $ terraform apply
  ```


### How to use the Bastion (Jump Server):

The Bastion can be used in 2 different ways
1. As a gateway to directly ssh into a private network EC2 instance:
  ```
  $ ssh -J terraform@<bastion_public_ip_address> username@<ec2_private_ip_address>
  ```
2. As a tunnel to access private resources:
  ```
  $ sshuttle -r terraform@<bastion_public_ip_address> <destination_private_ip_address>
  ```
  when running the above command you will get a message `c : Connected to server.`, if successful. Open a new terminal window, and you will be able to access destination resource directly.
  
  `<CTRL-C>` on the sshuttle window to terminate the tunnel.

## Canary Template

Canary template is a skeleton that can be used to build modules for each specific integration canary.
It provides a way to access base framework resources, like private subnet ids, to reuse them in the new resource deployment. 

## States Framework

The states framework deploys 2 resources:
* An S3 bucket to save state files from the different canaries
* A DynamoDB table to save lock files

As this module create resources needed by all the other modules/frameworks it has to be run prior to any other deployment. It only needs to ber run once

### Usage:
  ```
  $ terraform init
  
  $ terraform plan
  
  $ terraform apply
  ```
