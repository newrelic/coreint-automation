variable canary_name {
  type    = string
  default = "Coreint_Canaries"
}
variable network_cidr {
  type    = string
  default = "10.160.0.0/16"
}

# Bastion definitions
variable bastion_ubuntu_release {
  type    = string
  default = "jammy" # sets the preferred ubuntu release code name for the jump server. The latest version of each release will be used. i.e. jammy, focal, bionic, ...
}
variable bastion_instance_type {
  type    = string
  default = "t2.medium" # https://aws.amazon.com/ec2/instance-types/
}

# EKS Cluster definitions
variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.24"
}
variable nodes_instance_type {
  type    = string
  default = "t2.medium" # https://aws.amazon.com/ec2/instance-types/
}
variable nodes_ami_type {
  type    = string
  default = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
}