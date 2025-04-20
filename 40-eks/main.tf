resource "aws_key_pair" "eks" {
  key_name   = "expense-eks-terraform"
  # public_key = file("~/.ssh/eks_key.pub")
  # you can paste the public key directly like this
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCox4/d5QvxJApesUGZRod8ECDGE5dBdX+9j0KxvMKAWjZIeoklqcTR+kJouCVHdiyOkrReKuj95ppi+t5t22C/nOaHa3PLf8c5XZJ1t3NAJK608gIf1tHONg9kK07WU41beb/JYkdlbXWL+P83acx5/EIpch/Ur5v7oUg5ANCwOSKMEaabiUvWxJ8QDDIn+ZKn5NIj7h54O+4qTTTEDdbdtm5OSdYkIuVDqCWRr/XZtWCSAo5idEryPnbYhb3MqE3I2Z+tdF4J1o8eYgf/CcOg6maJP0V9LBPJb+cx+ehY+XhQb18ZgHLuAm8SHCYO2WbRu74egYbYbrU6FXelpW2T9P7Ru35iREWS/BRJ6CVW6/Ghi1+8CbSeyZDuF6UfMcmA0IfHgd+Q2dLXrOQdpQ0379kiuIYCwV+RvBDsgC7dAA3mjVXcpBgGTArhbiWw1umludJlOk90GO+FxsIywvd2z7E/Wzpb04O6IubEFgywEdeTk/vTMMQ8izXz7GlHQLs= HAI@DESKTOP-GNJ3GN1
"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                  = local.name
  cluster_version               = "1.31"                        #later we upgrade to 1.32
  create_node_security_group    = false                         # This is for worker nodes.
  create_cluster_security_group = false                         # This is for Control Plane.
  cluster_security_group_id     = local.eks_control_plane_sg_id # This is for Control Plane.
  node_security_group_id        = local.eks_node_sg_id          # This is for worker nodes.

  #bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    metrics-server         = {}
  }

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      #ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      key_name       = aws_key_pair.eks.key_name

      min_size     = 2 #2 Node cluster
      max_size     = 10
      desired_size = 2

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy       = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEFSCSIDriverPolicy       = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
    }

    # green = {
    #   min_size     = 2
    #   max_size     = 10
    #   desired_size = 2
    #   iam_role_additional_policies = {
    #     AmazonEBSCSIDriverPolicy       = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonEFSCSIDriverPolicy       = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    #     ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    #   }
    #   key_name = aws_key_pair.eks.key_name
    # }
  }
  tags = merge(
    var.common_tags,
    {
      Name = local.name
    }
  )

}