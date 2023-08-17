# Base Framework

Base framework builds basic infrastructure to deploy canary resources. When applied, terraform will create:
* 1 Main VPC network 
* 1 Public subnet from the main VPC address block
* 3 Private subnets from the main VPC address block (1 in each availability zone)
* 1 Internet Gateway to allow outbound communication
* 1 NAT Gateway to allow outbound communication from resources in the private subnets
* 3 Route Tables (Default, Public and Private)
* 3 Security Groups (VPC Traffic, EKS and EKS Nodes)
* 1 EKS Cluster (On the Private subnet)
* 2 IAM Roles (EKS and EKS nodes)
* 1 Bastion EC2 Ubuntu instance (Jump Server) on the public subnet allowing external ICMP and SSH traffic
* TLS Certificate and SSH Key

**IMPORTANT**: All state and locks for this terraform module are held in the S3 bucket and DynamoDB table created by the [states framework](../states_framework/README.md). Therefore, it is important the states_framework module to be run prior to base_framework.

### Usage:
  ```
  $ terraform init
  
  $ terraform plan
  
  $ terraform apply
  ```


### Setting up kubeconfig to connect to EKS Cluster
1. Retrieve the name of the EKS Cluster:
  ```
  $ aws eks list-clusters
  ```
2. Setup kubeconfig to connect to the new cluster:
  ```
  $ aws eks update-kubeconfig --name <cluster_name>
  ```  
3. Check if the new configuration is active:
  ```
  $ kubectl cluster-info
  ```  


### How to use the Bastion (Jump Server):

#### SSH into canaries
As a gateway to directly ssh into a private network EC2 instance:
  ```shell
  ssh -o ProxyCommand="ssh -W %h:%p terraform@<bastion_public_ip_address> -i Canaries-Key.pem" terraform@<ec2_private_ip_address> -i Canaries-Key.pem
  ```
  
  Or by using the ssh config

  ```
  Host canary
    Hostname <ec2_private_ip_address>
    ProxyCommand ssh -W %h:%p bastion
    User terraform
    IdentityFile path/to/ssh/Canaries-Key.pem
    Port 22

  Host bastion
    Hostname <bastion_public_ip_address>
    User terraform
    IdentityFile path/to/ssh/Canaries-Key.pem
    Port 22
  ```

  and ssh with:
  
  ```shell
  ssh canary
  ```

  Note that the terraform user must be created into the canary with the base framework public ssh key as authorized key.

#### Tunnel to services
As a tunnel to access private resources:
  TODO: specify the SSH Identity key for the connection.
  ```
  $ sudo sshuttle -r terraform@<bastion_public_ip_address> <network_cidr_behind_bastion>
  ```
  when running the above command you will get a message `c : Connected to server.`, if successful. Open a new terminal window, and you will be able to access destination resource directly with their internal IP address/dns name.
  
  `<CTRL-C>` on the sshuttle window to terminate the tunnel.
