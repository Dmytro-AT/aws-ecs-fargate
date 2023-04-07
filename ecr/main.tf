# create an ECR repo at the app/image level
resource "aws_ecr_repository" "api" {
  name                 = "project-dev"
}

resource "aws_ecr_lifecycle_policy" "repopolicy" {
  repository = aws_ecr_repository.api.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

output "docker_registry" {
  value = aws_ecr_repository.api.repository_url
}
