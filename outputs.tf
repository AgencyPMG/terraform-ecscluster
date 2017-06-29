output "server_role_name" {
    value = "${aws_iam_role.server.name}"
}

output "server_role_arn" {
    value = "${aws_iam_role.server.name}"
}

output "server_instance_profile_id" {
    value = "${aws_instance_profile.server.id}"
}

output "ecs_role_name" {
    value = "${aws_iam_role.ecs.name}"
}

output "ecs_role_arn" {
    value = "${aws_iam_role.ecs.name}"
}

output "server_security_group_id" {
    value = "${aws_security_group.server.id}"
}

output "ecs_cluster_name" {
    value = "${aws_ecs_cluster.name.name}"
}

output "launch_configuration_name" {
    value = "${aws_launch_configuration.ecs.name}"
}

output "asg_id" {
    value = "${aws_autoscaling_group.ecs.id}"
}

output "asg_arn" {
    value = "${aws_autoscaling_group.ecs.arn}"
}

output "asg_name" {
    value = "${aws_autoscaling_group.ecs.name}"
}
