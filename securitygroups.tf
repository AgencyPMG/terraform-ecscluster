resource "aws_security_group" "server" {
  name        = "ecs-server@${var.cluster_name}"
  description = "Default security group for the ${var.cluster_name} ECS servers"
  vpc_id      = "${var.vpc_id}"

  tags {
    Application = "${var.app}"
    Environment = "${var.env}"
  }
}
