# Base Framework

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

**IMPORTANT**: All state and locks for this terraform module are held in the S3 bucket and DynamoDB table created by the [states framework](../states_framework/README.md). Therefore, it is important the states_framework module to be run prior to base_framework.

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
  $ sudo sshuttle -r terraform@<bastion_public_ip_address> <network_cidr_behind_bastion>
  ```
  when running the above command you will get a message `c : Connected to server.`, if successful. Open a new terminal window, and you will be able to access destination resource directly with their internal IP address/dns name.
  
  `<CTRL-C>` on the sshuttle window to terminate the tunnel.
