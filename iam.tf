data "aws_iam_policy_document" "server" {
    statement {
        sid = "AllowAssumeRole"
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "server" {
    name = "ecs-server@${var.app}${var.env}"
    assume_role_policy = "${data.aws_iam_policy_document.server.json}"
}

resource "aws_iam_role_policy_attachment" "server_default" {
    role = "${aws_iam_role.server.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "server" {
    name = "ecs-server@${var.app}${var.env}"
    role = "${aws_iam_role.server.id}"
}

data "aws_iam_policy_document" "ecs" {
    statement {
        sid = "AllowAssumeRole"
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "ecs" {
    name = "ecs@${var.app}${var.env}"
    assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_default" {
    role = "${aws_iam_role.ecs.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
