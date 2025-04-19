# we are splitting the public subnet id's from string to string list and getting 1st subnet id using index 0 #

locals {
  public_subnet_id = split(",", data.aws_ssm_parameter.public_subnet_ids.value)[0]
}