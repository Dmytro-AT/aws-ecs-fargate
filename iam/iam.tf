###===============  roles  ================###
resource "aws_iam_policy" "secretsmanager_GetSecretValue" {
  name = "secretsmanager_GetSecretValue"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  count      = length(var.iam_policy_arn)
  policy_arn = var.iam_policy_arn[count.index]
}

output "execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

