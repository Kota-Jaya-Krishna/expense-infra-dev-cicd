#data source are useful to read the existing information#

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name}/${var.environment}/vpc_id"
}

# we will get the public subnet ids in string type, now we need to convert from string type to string list using some functions this is placed in locals(please check locals.tf#
data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/private_subnet_ids"
}

data "aws_ssm_parameter" "eks_control_plane_sg_id" {
  name = "/${var.project_name}/${var.environment}/eks_control_plane_sg_id"
}

data "aws_ssm_parameter" "eks_node_sg_id" {
  name = "/${var.project_name}/${var.environment}/eks_node_sg_id"
}