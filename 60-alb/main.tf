# NOTE: We are creating the alb for frontend servers using module concept #
# This is Public Load balancer #

module "alb" {
  source = "terraform-aws-modules/alb/aws"    # By default it will pick from GITHUB #
  internal = false

  # expense-dev-app-alb#
  name    = "${var.project_name}-${var.environment}-ingress-alb"
  vpc_id  = data.aws_ssm_parameter.vpc_id.value
  subnets = local.public_subnet_ids     # A list of subnet IDs to attach to the LB, as this LB is for public subnets, we need to add public subnets # 
  create_security_group = false 
  security_groups = [local.alb_ingress_sg_id]
  enable_deletion_protection = false
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-ingress-alb"
    }
  )
} 

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.ingress_alb_certificate_arn

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from Frontend WEB ALB</h1> "
      status_code  = "200"
  }
}
}

#expense-dev.learndevopsacademy.online
resource "aws_route53_record" "web_alb" {
  zone_id = var.zone_id
  name    =  "expense-${var.environment}.${var.domain_name}"   
  type    = "A"


# these are ALB DNS and zone information.here we have used alias block,please try to check manually in GUI, so u can understand #
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["expense-${var.environment}.${var.domain_name}"]
    }
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = local.resource_name
  port     = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = local.vpc_id
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    protocol = "HTTP"
    port = 8080
    path = "/"
    matcher = "200-299"
    interval = 10
  }
}