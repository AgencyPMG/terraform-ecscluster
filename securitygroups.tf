resource "aws_security_group" "server" {
    name = "ecs-server@${var.app}${var.env}"
    description = "Default security group for the ECS servers"
    vpc_id = "${var.vpc_id}"
    tags {
        Application = "${var.app}"
        Environment = "${var.env}"
    }
}
