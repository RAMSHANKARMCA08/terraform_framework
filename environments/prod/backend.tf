terraform {
  backend "s3" {
    bucket         = "REPLACE_ME_TERRAFORM_STATE_BUCKET"
    key            = "prod/platform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE_ME_TERRAFORM_LOCK_TABLE"
    encrypt        = true
  }
}
