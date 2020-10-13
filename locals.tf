locals {
  subnet_ids = concat(var.asg_subnets, var.subnet_ids)
}
