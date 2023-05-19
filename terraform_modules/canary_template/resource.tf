# This is just an example template on how to fetch resources from the base framework and use
# them for creating new resources like EC2 instances, Databases, etc...
#
# i.e. the following code will retrieve the subnets used by the base vpc so these can be used
# to allocate new resources
#
# DO NOT FORGET to replace "resource_name" with a friendly name of the resource being deployed

resource aws_db_subnet_group resource_name {
  name       = "resource_name"
  subnet_ids = [
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[0].id,
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[1].id,
    data.terraform_remote_state.base_framework.outputs.common_networking.aws_subnet.private_subnets[2].id,
  ]
}
