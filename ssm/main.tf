##=============  api variables =====================
data "terraform_remote_state" "ecs" {
  backend = "s3"
  config  = {
    bucket = "project-terraform-state"                   ## Bucket from where to GET Terraform State
    key    = "development/ecs/terraform.tfstate"         ## Object name in the bucket to GET Terraform state
    region = "eu-central-1"                              ## Region where bucket created
  }
}

resource "aws_ssm_parameter" "APP_URL" {
  name  = "${upper(var.env)}_APP_URL"
  type  = "String"
  value = "http://${data.terraform_remote_state.ecs.outputs.APP_URL}"
  tags  = {
    environment = var.env
  }
}

resource "aws_ssm_parameter" "NODE_ENV" {
  name  = "${upper(var.env)}_NODE_ENV"
  type  = "String"
  value = "development"
  tags  = {
    environment = var.env
  }
}

resource "aws_ssm_parameter" "MONGO_URI" {
  name  = "${upper(var.env)}_MONGO_URI"
  type  = "String"
  value = "mongodb+srv://project-dev:123321.mongodb.net"
  tags  = {
    environment = var.env
  }
}

resource "aws_ssm_parameter" "REDIS_HOST" {
  name  = "${upper(var.env)}_REDIS_HOST"
  type  = "String"
  value = "redis://default:123321@redis-1231.cloud.redislabs.com"
  tags  = {
    environment = var.env
  }
}

resource "aws_ssm_parameter" "REDIS_PORT" {
  name  = "${upper(var.env)}_REDIS_PORT"
  type  = "String"
  value = "12332"
  tags  = {
    environment = var.env
  }
}
##=================  END  =====================
