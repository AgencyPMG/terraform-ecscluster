variable "app" {
    type = "string"
    description = "The application name, used in the `Application` tags."
}

variable "env" {
    type = "string"
    description = "The application environment (prod, staging, etc). Pass in terraform.env here if you like. Used in the `Environment` tags."
}

variable "vpc_id" {
    type = "string"
    description = "The VPC in which the ECS cluster will be placed."
}

variable "cluster_name" {
    type = "string"
    description = "The name with which the ECS cluster will be created."
}

variable "instance_ami" {
    type = "string" 
    description = "The AMI for the container servers. Espects one of the ECS optimizes AMIs."
}

variable "instance_type" {
    type = "string" 
    description = "The instance type of the container servers."
}

variable "instance_keypair" {
    type = "string"
    description = "The keypair with which the instances will be created."
}

variable "asg_subnets" {
    type = "list"
    description = "The subnets into which the ECS servers should be placed."
}

variable "asg_max_size" {
    default = 1
    description = "Max size of the auto scaling group"
}

variable "asg_min_size" {
    default = 1
    description = "Min size of the auto scaling group"
}

variable "asg_enabled" {
    default = true
    description = "Whether or not to create the autoscaling group."
}