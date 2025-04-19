module "mysql_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "mysql"
  sg_description = "Created for MySQL instance in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "bastion_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "bastion"
  sg_description = "Created for bastion instance in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}


# Ports 22, 443, 1194, 943 --> VPN ports

module "vpn_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "vpn"
  sg_description = "Created for VPN instance in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "alb_ingress_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "app_alb_sg"
  sg_description = "Created for backend ALB instance in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "eks_control_plane_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "eks_control_plane"
  sg_description = "Created for EKS control plane in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "eks_node_sg" {
  source         = "git::https://github.com/Kota-Jaya-Krishna/terraform-aws-security-group.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "eks_node"
  sg_description = "Created for EKS worker nodes in expense dev"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}


# EKS control plane accepting traffic from worker node.
# It is required to allow communication between the worker nodes and the control plane for critical Kubernetes operations.

resource "aws_security_group_rule" "eks_control_plane_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks_node_sg.sg_id
  security_group_id        = module.eks_control_plane_sg.sg_id
}

# EKS worker node accepting traffic from EKS control plane
# It is required for the EKS control plane (managed by AWS) to communicate with worker nodes for:
# Deploying workloads,Managing container scheduling.Health checks, monitoring, and updates.

resource "aws_security_group_rule" "eks_node_eks_control_plane" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks_control_plane_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}

# worker node accepting traffic from ALB ingress (for NodePort)

# resource "aws_security_group_rule" "node_alb_ingress" {
#   type                     = "ingress"
#   from_port                = 30000
#   to_port                  = 32767
#   protocol                 = "tcp"
#   source_security_group_id = module.alb_ingress_sg.sg_id
#   security_group_id        = module.eks_node_sg.sg_id
# }

# worker Node is accepting traffic form vpc CIDR range. POD in worker node should accept other POD in another node. so we have to give VPC CIDR range.
#POD to POD communication.

resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"   #This is the huge mistake if value is tcp, DNS will work in EKS, UDP traffic is required. so make it all traffic
  cidr_blocks       = ["10.0.0.0/16"] # our private IP address range
  security_group_id = module.eks_node_sg.sg_id

}

# worker nodes accepting traffic from Bastion host
resource "aws_security_group_rule" "nodes_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}


# APP ALB accepting traffic from bastion
resource "aws_security_group_rule" "alb_ingress_bastion" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.alb_ingress_sg.sg_id
}

# APP ALB accepting traffic from bastion
resource "aws_security_group_rule" "alb_ingress_bastion_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.alb_ingress_sg.sg_id
}

# APP ALB accepting traffic from public
resource "aws_security_group_rule" "alb_ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb_ingress_sg.sg_id
}


resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion_sg.sg_id
}

# mysql accepting traffic from bastion #

resource "aws_security_group_rule" "mysql_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "mysql_eks_nodes" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.eks_node_sg.sg_id
  security_group_id        = module.mysql_sg.sg_id
}

#When you use kubectl from the bastion host to interact with the EKS cluster, all API calls are sent over HTTPS to port 443 of the EKS control plane.
#The Kubernetes API server on the EKS control plane listens on port 443 for incoming HTTPS requests.
resource "aws_security_group_rule" "eks_control_plane_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.eks_control_plane_sg.sg_id
}


# resource "aws_security_group_rule" "eks_worker_nodes_bastion" {
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = module.bastion_sg.sg_id
#   security_group_id        = module.eks_node_sg.sg_id
# }


# resource "aws_security_group_rule" "eks_worker_nodes_bastion_http" {
#   type                     = "ingress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   source_security_group_id = module.bastion_sg.sg_id
#   security_group_id        = module.eks_node_sg.sg_id
# }


# EKS nodes is accepting incoming requests from ALB(in target group we can see the POD IP address, so POD(EKS Nodes) should accept traffic from ALB.
resource "aws_security_group_rule" "eks_node_alb_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.alb_ingress_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}