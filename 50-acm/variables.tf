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

variable "domain_name" {
    default = "learndevopsacademy.online"
}

variable "zone_id" {
    default = "Z04639513Q3IO8K62QY6W"
}