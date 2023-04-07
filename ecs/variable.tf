variable "region" {
  description = "AWS Region for ECS"
  type        = string
  default     = "eu-central-1"
}

variable "api-name" {
  default = "project"
}

variable "alb_ports" {
  description = "List of Ports to open for server"
  type        = list
  default     = ["80", "443"]
}

variable "app_ports" {
  description = "List of Ports to open for server"
  type        = list
  default     = ["8000"]
}

variable "env" {
  default = "dev"
}

variable "common_tags" {
  description = "Common Tags"
  type        = map
  default = {
    Project     = "project"
    Environment = "development"
  }
}

variable "api_image" {
  default = "000000000000.dkr.ecr.eu-central-1.amazonaws.com/project-dev:latest"
}

variable "api_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 8000
}

variable "api_count" {
  description = "Number of docker containers to run"
  default     = 1
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

