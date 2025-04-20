variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        project_name = "expense"
        environment = "dev"
        Terraform = "True"
    }
}