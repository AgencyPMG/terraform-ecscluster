resource "aws_security_group" "server" {
  name        = "ecs-server@${var.cluster_name}"
  description = var.sg_description == "" ? local.default_sg_description : var.sg_description
  vpc_id      = var.vpc_id

  tags = {
    Application = var.app
    Environment = var.env
  }
}

