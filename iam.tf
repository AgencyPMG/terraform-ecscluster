data "aws_iam_policy_document" "server" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "ecs-server@${var.cluster_name}"
  assume_role_policy = "${data.aws_iam_policy_document.server.json}"
}

resource "aws_iam_role_policy_attachment" "server_default" {
  role       = "${aws_iam_role.server.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "server" {
  name = "ecs-server@${var.cluster_name}"
  role = "${aws_iam_role.server.id}"
}

data "aws_iam_policy_document" "ecs" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs" {
  name               = "ecs@${var.cluster_name}"
  assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_default" {
  role       = "${aws_iam_role.ecs.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "task-exec" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task-exec" {
  name               = "ecs-task-exec@${var.cluster_name}"
  assume_role_policy = "${data.aws_iam_policy_document.task-exec.json}"
}

resource "aws_iam_role_policy_attachment" "task-exec" {
  role       = "${aws_iam_role.task-exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
