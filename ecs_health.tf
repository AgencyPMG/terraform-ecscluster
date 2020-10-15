locals {
  ecs_health_name = "ecs-health-${var.app}-${var.env}-${random_string.health-task-rando.result}"
}

resource "random_string" "health-task-rando" {
  length  = 4
  special = false
}

module "ecs-health" {
  source             = "git@github.com:AgencyPMG/terraform-lambda-function.git"
  app                = local.ecs_health_name
  env                = var.env
  name               = local.ecs_health_name
  runtime            = "python3.7"
  handler            = "main.handle"
  path               = "${path.module}/ecs_health"
  subnet_ids         = local.subnet_ids
  security_group_ids = [aws_security_group.server.id]
  function_version   = filemd5("${path.module}/ecs_health/main.py")
  timeout            = "120"

  environment = {
    CLUSTER_NAME = aws_ecs_cluster.main.name
  }
}

resource "aws_cloudwatch_event_rule" "ecs-health" {
  name                = local.ecs_health_name
  schedule_expression = "rate(20 minutes)"
}

resource "aws_lambda_permission" "ecs-health" {
  statement_id  = "AllowExecFromScheduledEvent"
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.ecs-health.function_name
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

resource "aws_cloudwatch_event_target" "ecs-health" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = module.ecs-health.function_arn
}

data "aws_iam_policy_document" "ecs-health-lambda" {
  statement {
    sid    = "AllowDescribeContainerInstance"
    effect = "Allow"
    actions = [
      "ecs:DescribeContainerInstances",
      "ecs:ListContainerInstances",
    ]
    resources = [
      aws_ecs_cluster.main.arn,
    ]
  }

  statement {
    sid     = "AllowSetInstanceHealth"
    effect  = "Allow"
    actions = ["autoscaling:SetInstanceHealth"]
    # doesn't seem to be a way to limit this to a single auto scaling group...
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ecs-health-lambda" {
  name        = local.ecs_health_name
  policy      = data.aws_iam_policy_document.ecs-health-lambda.json
  description = "Allows lambda to describe container instances and set instance health"
}

resource "aws_iam_role_policy_attachment" "ecs-health-lambda" {
  role       = module.ecs-drain.role_name
  policy_arn = aws_iam_policy.ecs-health-lambda.arn
}
