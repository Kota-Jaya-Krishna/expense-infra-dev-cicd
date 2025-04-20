resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}/${var.environment}/backend"     #Repository name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}/${var.environment}/frontend"    #Repository name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#NOTE: In CICD pipeline, after building an image we will push to ECR by using IMage URI.