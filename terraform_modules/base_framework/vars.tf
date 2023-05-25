variable canary_name {
  type    = string
  default = "Coreint Canaries"
}
variable network_cidr {
  type    = string
  default = "10.160.0.0/16"
}
variable ubuntu_release {
  type    = string
  default = "jammy" # sets the preferred ubuntu release code name for the jump server. The latest version of each release will be used. i.e. jammy, focal, bionic, ...
}
variable instance_type {
  type    = string
  default = "t2.medium" # https://aws.amazon.com/ec2/instance-types/
}
