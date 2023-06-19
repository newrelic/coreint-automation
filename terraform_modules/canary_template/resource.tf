# This is just an example template on how to fetch resources from the base framework and use
# them for creating new resources like EC2 instances, Databases, etc...
#
# DO NOT FORGET to replace "resource_name" with a friendly name of the resource being deployed

resource aws_db_subnet_group resource_name {
  name       = "resource_name"

  # the following code will retrieve the subnets used by the base vpc so these can be used
  # to allocate new resources.
  subnet_ids = [
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[0].id,
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[1].id,
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[2].id,
  ]

  # the following code will retrieve the security groups that should be assigned to a new resource
  # allowing it to be accessible from all other resources within the main vpc.
  vpc_security_group_ids      = [
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_default_security_group.default.id,
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_security_group.internal_traffic.id
  ]

  # the following code will retrieve the canary ssh key name that can be assigned to an EC2 instance
  # to allow access to it.
  key_name = data.terraform_remote_state.base_framework.outputs.tls_ca_and_ssh_keys.aws_key_pair.ssh_key_pair.key_name
}
