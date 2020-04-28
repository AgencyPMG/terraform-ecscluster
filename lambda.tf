module "check-ecs-tasks" {
  source             = "git@github.com:AgencyPMG/terraform-lambda-function.git?ref=tf_0.12"
  app                = var.app
  env                = var.env
  name               = "check-ecs-tasks-${var.app}-${var.env}"
  runtime            = "python3.7"
  handler            = "main.handle"
  path               = "${path.module}/check_tasks"
  subnet_ids         = var.asg_subnets
  security_group_ids = [aws_security_group.server.id]
  function_version   = filemd5("${path.module}/check_tasks/main.py")
  environment = {
    APP_NAME        = var.app
    APP_ENVIRONMENT = var.env
    SNS_TOPIC_ARN   = aws_sns_topic.ecs-task-alerts.arn
  }
}

resource "aws_cloudwatch_event_rule" "check-ecs-tasks" {
  name                = "check-ecs-tasks-${var.app}${var.env}"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "check-ecs-tasks" {
  rule      = aws_cloudwatch_event_rule.check-ecs-tasks.name
  target_id = "check-ecs-tasks-${var.app}-${var.env}"
  arn       = module.check-ecs-tasks.function_arn
}

resource "aws_lambda_permission" "check-ecs-tasks" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.check-ecs-tasks.function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check-ecs-tasks.arn
}

resource "aws_iam_role_policy" "check-ecs-tasks-perms" {
  name   = "check-ecs-tasks@${var.app}${var.env}"
  role   = module.check-ecs-tasks.role_name
  policy = data.aws_iam_policy_document.check-ecs-tasks-perms.json
}

data "aws_iam_policy_document" "check-ecs-tasks-perms" {
  statement {
    sid    = "AllowPublishSNS"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [aws_sns_topic.ecs-task-alerts.arn]
  }

  statement {
    sid    = "AllowECSPermissions"
    effect = "Allow"
    actions = [
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDynamoAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
    ]
    resources = [aws_dynamodb_table.ecs-task-alerts.arn]
  }
}

resource "aws_sns_topic" "ecs-task-alerts" {
  name = "ecs-task-alerts-${var.app}${var.env}"
}

resource "aws_sns_topic_subscription" "ecs-task-alerts" {
  topic_arn              = aws_sns_topic.ecs-task-alerts.arn
  protocol               = "https"
  endpoint               = "https://alerts.pmg.com/${var.app}/aws/generic"
  endpoint_auto_confirms = true
}

resource "aws_dynamodb_table" "ecs-task-alerts" {
  name           = "ecs-task-alerts-${var.app}${var.env}"
  write_capacity = 1
  read_capacity  = 1

  hash_key = "detail_hash"

  attribute {
    name = "detail_hash"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "expires_ts"
  }
}
