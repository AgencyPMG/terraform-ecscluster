resource "aws_launch_configuration" "ecs" {
  count                = var.asg_enabled ? 1 : 0
  name_prefix          = var.cluster_name
  image_id             = var.instance_ami
  instance_type        = var.instance_type
  ebs_optimized        = var.ebs_optimized
  key_name             = var.instance_keypair
  security_groups      = [aws_security_group.server.id]
  iam_instance_profile = aws_iam_instance_profile.server.id

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash

echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
${var.additional_bash_user_data}

EOF

}

resource "aws_autoscaling_group" "ecs" {
  count                = var.asg_enabled ? 1 : 0
  name                 = element(aws_launch_configuration.ecs.*.name, 0)
  max_size             = var.asg_max_size
  min_size             = var.asg_min_size
  vpc_zone_identifier  = local.subnet_ids
  launch_configuration = aws_launch_configuration.ecs[0].name

  enabled_metrics = [
    "GroupTotalInstances",
    "GroupDesiredCapacity",
    "GroupTerminatingInstances",
    "GroupPendingInstances",
    "GroupInServiceInstances",
  ]

  lifecycle {
    create_before_destroy = true
  }

  initial_lifecycle_hook {
    name                 = "drain-tasks"
    default_result       = "ABANDON"
    heartbeat_timeout    = "900"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"

    notification_target_arn = aws_sns_topic.ecs-drain.arn
    role_arn                = aws_iam_role.ecs-drain.arn
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name} ecs server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = var.app
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "ecs-drain" {
  name               = "ECSDrain@${var.app}-${var.env}-${random_string.drain-task-rando.result}"
  assume_role_policy = data.aws_iam_policy_document.ecs-drain.json
}

data "aws_iam_policy_document" "ecs-drain" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs-drain" {
  role       = aws_iam_role.ecs-drain.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
}

resource "aws_sns_topic" "ecs-drain" {
  name = "${var.app}-${var.env}-ecs-drain"
}
