# =============================================
# main.tf
# Root configuration file
# Connects all modules together
# =============================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "ukb-dev-euw2-s3-tf-state"
    key    = "nhs-prescribing/terraform.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region  = var.aws_region

  default_tags {
    tags = {
      Project     = "nhs-prescribing-pipeline"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "chips.lam"
      DataClass   = "public"
    }
  }
}

# =============================================
# Modules
# =============================================

module "s3" {
  source      = "./modules/s3"
  environment = var.environment
}

module "iam" {
  source            = "./modules/iam"
  environment       = var.environment
  bronze_bucket_arn = module.s3.bronze_bucket_arn
  silver_bucket_arn = module.s3.silver_bucket_arn
  gold_bucket_arn   = module.s3.gold_bucket_arn
  athena_bucket_arn = module.s3.athena_bucket_arn
  scripts_bucket_arn = module.s3.scripts_bucket_arn
}

module "lambda" {
  source             = "./modules/lambda"
  environment        = var.environment
  lambda_role_arn    = module.iam.lambda_role_arn
  bronze_bucket_name = module.s3.bronze_bucket_name
  nhs_api_base_url   = var.nhs_api_base_url
  nhs_dataset_id     = var.nhs_dataset_id
  lambda_timeout     = var.lambda_timeout
  lambda_memory      = var.lambda_memory
  glue_workflow_name = module.glue.workflow_name
}

module "eventbridge" {
  source           = "./modules/eventbridge"
  environment      = var.environment
  lambda_arn       = module.lambda.lambda_arn
  lambda_func_name = module.lambda.lambda_func_name
  lambda_schedule  = var.lambda_schedule
}

module "glue" {
  source             = "./modules/glue"
  environment        = var.environment
  glue_role_arn      = module.iam.glue_role_arn
  bronze_bucket_name = module.s3.bronze_bucket_name
  silver_bucket_name = module.s3.silver_bucket_name
  gold_bucket_name   = module.s3.gold_bucket_name
  scripts_bucket     = module.s3.scripts_bucket_name
  nhs_api_base_url   = var.nhs_api_base_url
  nhs_resource_id    = var.nhs_resource_id
}

module "athena" {
  source             = "./modules/athena"
  environment        = var.environment
  athena_bucket_name = module.s3.athena_bucket_name
  gold_bucket_arn    = module.s3.gold_bucket_arn
  glue_database_name = module.glue.glue_database_name
}
