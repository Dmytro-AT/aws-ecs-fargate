data "aws_availability_zones" "available" {}

#----------------------------- NETWORK -----------------------------------------
module "vpc-dev" {
  source          = "git@github.com:Dmytro-AT/modules.git//aws_network"
  env             = var.env
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
#-------------------------------- END ------------------------------------------
#--------------------------- Security group ------------------------------------
module "aws_sg_alb" {
  source      = "git@github.com:Dmytro-AT/modules.git//aws_security_group"
  name        = "${var.env}-api-alb-sg"
  env         = var.env
  vpc_id      = module.vpc-dev.vpc_id
  allow_ports = var.alb_ports
}

module "aws_sg_ecs" {
  source      = "git@github.com:Dmytro-AT/modules.git//aws_security_group"
  name        = "${var.env}-api-ecs-sg"
  env         = var.env
  cidr        = module.vpc-dev.cidr_block
  vpc_id      = module.vpc-dev.vpc_id
  allow_ports = var.app_ports
}
#------------------------------- END -------------------------------------------
#------------------------------- LOGS ------------------------------------------
resource "aws_cloudwatch_log_group" "project-dev-api_lg" {
  name              = "/ecs/project-dev-api"
  retention_in_days = 30
  tags              = {
    Name = "project-dev-api-lg"
  }
}

resource "aws_cloudwatch_log_stream" "project-dev-api_ls" {
  name           = "project-dev-api"
  log_group_name = aws_cloudwatch_log_group.project-dev-api_lg.name
}
#-------------------------------- END ------------------------------------------
#-------------------------------  ALB ------------------------------------------
resource "aws_alb" "project-dev-api-alb" {
  name                       = "project-dev-api-alb"
  subnets                    = module.vpc-dev.private_subnets
  security_groups            = [module.aws_sg_alb.security_group_id]
  drop_invalid_header_fields = false
  enable_deletion_protection = false
  enable_http2               = true
  idle_timeout               = 60
  load_balancer_type         = "application"
  tags                       = var.common_tags
}

resource "aws_alb_target_group" "project-dev-api-alb-tg" {
  name                               = "project-dev-api-alb-tg"
  port                               = 80
  protocol                           = "HTTP"
  vpc_id                             = module.vpc-dev.vpc_id
  target_type                        = "ip"
  deregistration_delay               = 300
  lambda_multi_value_headers_enabled = false
  proxy_protocol_v2                  = false
  slow_start                         = 0

  health_check {
    path = "/"                            # health
  }

  tags = var.common_tags
}

resource "aws_alb_listener" "project-dev-api-listen" {
  load_balancer_arn = aws_alb.project-dev-api-alb.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.project-dev-api-alb-tg]

  default_action {
    target_group_arn = aws_alb_target_group.project-dev-api-alb-tg.arn
    type             = "forward"
  }
}
#-------------------------------- END ------------------------------------------
#------------------------------   ECS   ----------------------------------------
data "aws_ecs_task_definition" "project-dev-api" {
  task_definition = aws_ecs_task_definition.project-dev-api.family
}

resource "aws_ecs_cluster" "project-dev-api-cluster" {
  name = "project-dev-api-cluster"
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config  = {
    bucket = "project-terraform-state"                   ## Bucket from where to GET Terraform State
    key    = "development/iam/terraform.tfstate"         ## Object name in the bucket to GET Terraform state
    region = "eu-central-1"                              ## Region where bucket created
  }
}

data "template_file" "task_def" {
  template = file("./task-definition.json")
  vars     = {
    api_name       = "${var.api-name}-${var.env}-api"
    api_image      = var.api_image
    api_port       = var.api_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    region         = var.region
    env            = var.env
  }
}

resource "aws_ecs_task_definition" "project-dev-api" {
  family                   = "project-dev-api"
  execution_role_arn       = data.terraform_remote_state.iam.outputs.execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE",]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.task_def.rendered
}

resource "aws_ecs_service" "main" {
  name                              = "project-dev-api-service"
  cluster                           = aws_ecs_cluster.project-dev-api-cluster.id
  task_definition                   = "${aws_ecs_task_definition.project-dev-api.family}:${max(aws_ecs_task_definition.project-dev-api.revision, data.aws_ecs_task_definition.project-dev-api.revision)}"
  desired_count                     = var.api_count
  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = 0
  platform_version                  = "LATEST"
  launch_type                       = "FARGATE"

  tags = {
    "env" = var.env
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    security_groups  = [module.aws_sg_ecs.security_group_id]
    subnets          = module.vpc-dev.private_subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.project-dev-api-alb-tg.id
    container_name   = "project-dev-api"
    container_port   = var.api_port
  }
  depends_on = [
    aws_alb_listener.project-dev-api-listen
  ]
}
#-------------------------------- END ------------------------------------------
