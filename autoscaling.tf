resource "aws_launch_configuration" "ecs" {
  count                = "${var.asg_enabled ? 1 : 0}"
  name_prefix          = "${var.cluster_name}"
  image_id             = "${var.instance_ami}"
  instance_type        = "${var.instance_type}"
  ebs_optimized        = "${var.ebs_optimized}"
  key_name             = "${var.instance_keypair}"
  security_groups      = ["${aws_security_group.server.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.server.id}"

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
  count                = "${var.asg_enabled ? 1 : 0}"
  name                 = "${element(aws_launch_configuration.ecs.*.name, 0)}"
  max_size             = "${var.asg_max_size}"
  min_size             = "${var.asg_min_size}"
  vpc_zone_identifier  = ["${var.asg_subnets}"]
  launch_configuration = "${aws_launch_configuration.ecs.name}"

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

  tag {
    key                 = "Name"
    value               = "${var.cluster_name} ecs server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "${var.app}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}
