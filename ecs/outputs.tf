output "APP_URL" {
  value = aws_alb.project-dev-api-alb.dns_name
  depends_on = [aws_alb.project-dev-api-alb]
}
