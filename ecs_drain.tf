locals {
  ecs_drain_name = "ecs-drain-${var.app}-${var.env}-${random_string.drain-task-rando.result}"
}

resource "random_string" "drain-task-rando" {
  length  = 4
  special = false
}

module "ecs-drain" {
  source             = "git@github.com:AgencyPMG/terraform-lambda-function.git"
  app                = local.ecs_drain_name
  env                = var.env
  name               = local.ecs_drain_name
  runtime            = "python3.7"
  handler            = "main.handle"
  path               = "${path.module}/ecs_drain"
  subnet_ids         = local.subnet_ids
  security_group_ids = [aws_security_group.server.id]
  function_version   = filemd5("${path.module}/ecs_drain/main.py")
  timeout            = "120"

  environment = {
    CLUSTER_NAME = aws_ecs_cluster.main.name
  }
}

resource "aws_sns_topic_subscription" "ecs-drain" {
  topic_arn = aws_sns_topic.ecs-drain.arn
  protocol  = "lambda"
  endpoint  = module.ecs-drain.function_arn
}

resource "aws_lambda_permission" "ecs-drain" {
  statement_id  = "ECSDrain"
  action        = "lambda:InvokeFunction"
  function_name = module.ecs-drain.function_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ecs-drain.arn
}

data "aws_iam_policy_document" "ecs-drain-lambda" {
  statement {
    sid    = "ECSDrainLambda"
    effect = "Allow"

    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeHosts",
      "ecs:ListContainerInstances",
      "ecs:SubmitContainerStateChange",
      "ecs:SubmitTaskStateChange",
      "ecs:DescribeContainerInstances",
      "ecs:UpdateContainerInstancesState",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "sns:Publish",
      "sns:ListSubscriptions",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ecs-drain-lambda" {
  name        = local.ecs_drain_name
  policy      = data.aws_iam_policy_document.ecs-drain-lambda.json
  description = "Allows Lambda to recieve notifications for ECS Draining"
}

resource "aws_iam_role_policy_attachment" "ecs-drain-lambda" {
  role       = module.ecs-drain.role_name
  policy_arn = aws_iam_policy.ecs-drain-lambda.arn
}
