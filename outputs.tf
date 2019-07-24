output "server_role_name" {
  value = "${aws_iam_role.server.name}"
}

output "server_role_arn" {
  value = "${aws_iam_role.server.arn}"
}

output "server_instance_profile_id" {
  value = "${aws_iam_instance_profile.server.id}"
}

output "ecs_role_name" {
  value = "${aws_iam_role.ecs.name}"
}

output "ecs_role_arn" {
  value = "${aws_iam_role.ecs.arn}"
}

output "server_security_group_id" {
  value = "${aws_security_group.server.id}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.main.name}"
}

output "ecs_cluster_arn" {
  value = "${aws_ecs_cluster.main.arn}"
}

output "launch_configuration_name" {
  value = "${length(aws_launch_configuration.ecs.*.name) > 0 ? element(aws_launch_configuration.ecs.*.name, 0) : ""}"
}

output "asg_id" {
  value = "${length(aws_autoscaling_group.ecs.*.id) > 0 ? element(aws_autoscaling_group.ecs.*.id, 0) : ""}"
}

output "asg_arn" {
  value = "${length(aws_autoscaling_group.ecs.*.id) > 0 ? element(aws_autoscaling_group.ecs.*.arn, 0) : ""}"
}

output "asg_name" {
  value = "${length(aws_autoscaling_group.ecs.*.id) > 0 ? element(aws_autoscaling_group.ecs.*.name, 0) : ""}"
}
