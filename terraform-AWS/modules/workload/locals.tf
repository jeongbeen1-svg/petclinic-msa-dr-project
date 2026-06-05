locals {
  namespace = var.namespace

  cluster_name = "${local.namespace}-eks"

  common_tags = {
    Environment = "dev"
    Project     = "Project3-MSA"
    ManagedBy   = "Terraform"
  }

  vpc_id                = var.vpc_id
  public_subnet_id      = var.public_subnet_id
  instance_type         = var.instance_type
  bastion_allowed_cidrs = var.bastion_allowed_cidrs
  all_admin_arns        = var.all_admin_arns

  # 배포할 마이크로서비스 목록 정의
  petclinic_services = toset([
    "config-server",
    "discovery-server",
    "api-gateway",
    "admin-server",
    "customers-service",
    "vets-service",
    "visits-service",
    "genai-service"
  ])
  
  ecr_registry = "906336681755.dkr.ecr.ap-northeast-2.amazonaws.com"
}