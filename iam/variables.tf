variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "ecsTaskExecutionRole"
}


variable "iam_policy_arn" {
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::006331960597:policy/secretsmanager_GetSecretValue"
  ]
}
